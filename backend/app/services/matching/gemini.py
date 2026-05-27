"""
Optional multimodal matcher (Gemini image + text).

Rate-limited (RPM-safe) with per-request throttle and 429/503 retries.
Default matching remains amazon_search; enable via MATCHING_PROVIDER=gemini.
"""

from __future__ import annotations

import asyncio
import json
import logging
import re
import time
from typing import Any

import httpx
from app.config import Settings
from app.services.matching.types import AmazonCandidateMatch

logger = logging.getLogger(__name__)

_ASIN_PATTERN = re.compile(r"^B[A-Z0-9]{9}$")
_RETRYABLE_MARKERS = ("429", "503", "resource exhausted", "too many requests", "unavailable")

# Process-wide throttle so consecutive find_candidates() respect RPM.
_rate_limiter: asyncio.Lock | None = None
_last_request_at: float = 0.0


class GeminiConfigError(Exception):
    """Gemini API key or model configuration is missing or invalid."""


def _is_retryable(exc: BaseException) -> bool:
    try:
        from google.api_core import exceptions as google_exceptions

        if isinstance(exc, google_exceptions.ResourceExhausted):
            return True
        if isinstance(exc, google_exceptions.ServiceUnavailable):
            return True
    except ImportError:
        pass
    message = str(exc).lower()
    return any(marker in message for marker in _RETRYABLE_MARKERS)


def _normalize_asin(raw: str) -> str | None:
    asin = raw.strip().upper()
    if _ASIN_PATTERN.fullmatch(asin):
        return asin
    return None


def _parse_candidates_payload(text: str) -> list[AmazonCandidateMatch]:
    try:
        data = json.loads(text)
    except json.JSONDecodeError as exc:
        raise ValueError(f"Gemini returned invalid JSON: {exc}") from exc

    rows: list[dict[str, Any]]
    if isinstance(data, list):
        rows = [r for r in data if isinstance(r, dict)]
    elif isinstance(data, dict):
        raw_rows = data.get("candidates")
        if not isinstance(raw_rows, list):
            raise ValueError("Gemini JSON must include a 'candidates' array")
        rows = [r for r in raw_rows if isinstance(r, dict)]
    else:
        raise ValueError("Gemini JSON must be an object or array")

    matches: list[AmazonCandidateMatch] = []
    for row in rows[:3]:
        asin = _normalize_asin(str(row.get("asin", "")))
        if asin is None:
            continue
        title = str(row.get("title") or "").strip() or asin
        try:
            confidence = float(row.get("confidence", 0.5))
        except (TypeError, ValueError):
            confidence = 0.5
        confidence = max(0.0, min(1.0, confidence))
        reasoning = row.get("reasoning")
        matches.append(
            AmazonCandidateMatch(
                asin=asin,
                amazon_url=f"https://www.amazon.com/dp/{asin}",
                title=title,
                confidence=confidence,
                reasoning=str(reasoning) if reasoning is not None else None,
            )
        )
    return matches


def _build_prompt(shopee_title: str, *, has_image: bool) -> str:
    image_hint = (
        "A product image from Shopee is attached. Use it together with the title."
        if has_image
        else "No image was provided; use the title only."
    )
    return (
        "You help match cross-border e-commerce listings from Shopee to Amazon US products.\n"
        f"{image_hint}\n\n"
        f"Shopee product title: {shopee_title}\n\n"
        "Return up to 3 likely Amazon matches as JSON with this exact shape:\n"
        '{"candidates":[{"asin":"B0XXXXXXXXX","title":"Amazon product title",'
        '"confidence":0.0,"reasoning":"short reason"}]}\n'
        "Rules:\n"
        "- asin must be a valid Amazon ASIN (B + 9 alphanumeric).\n"
        "- confidence is 0.0–1.0.\n"
        "- If unsure, return fewer candidates or an empty candidates array.\n"
        "- Respond with JSON only, no markdown."
    )


def _fetch_image_bytes(url: str, *, timeout_sec: float = 10.0) -> tuple[bytes, str] | None:
    try:
        with httpx.Client(timeout=timeout_sec, follow_redirects=True) as client:
            response = client.get(url)
            response.raise_for_status()
            content_type = response.headers.get("content-type", "image/jpeg").split(";")[0]
            if not content_type.startswith("image/"):
                content_type = "image/jpeg"
            return response.content, content_type
    except (httpx.HTTPError, OSError) as exc:
        logger.warning("Gemini matcher: could not fetch image %s: %s", url, exc)
        return None


def _call_gemini_sync(
    *,
    api_key: str,
    model_name: str,
    prompt: str,
    image: tuple[bytes, str] | None,
) -> str:
    try:
        import google.generativeai as genai
    except ImportError as exc:
        raise GeminiConfigError(
            "Install google-generativeai (see backend/requirements.txt)"
        ) from exc

    genai.configure(api_key=api_key)
    model = genai.GenerativeModel(
        model_name,
        generation_config=genai.GenerationConfig(
            response_mime_type="application/json",
            temperature=0.2,
        ),
    )

    parts: list[Any] = [prompt]
    if image is not None:
        image_bytes, mime_type = image
        parts.append({"mime_type": mime_type, "data": image_bytes})

    response = model.generate_content(parts)
    text = getattr(response, "text", None)
    if not text:
        raise RuntimeError("Gemini returned an empty response")
    return text.strip()


async def _wait_for_rate_limit(min_interval_sec: float) -> None:
    global _rate_limiter, _last_request_at
    if _rate_limiter is None:
        _rate_limiter = asyncio.Lock()

    async with _rate_limiter:
        now = time.monotonic()
        wait_sec = min_interval_sec - (now - _last_request_at)
        if wait_sec > 0:
            await asyncio.sleep(wait_sec)
        _last_request_at = time.monotonic()


class GeminiMatcher:
    def __init__(self, settings: Settings) -> None:
        self._settings = settings

    def _ensure_configured(self) -> None:
        if not self._settings.gemini_api_key.strip():
            raise GeminiConfigError("Set GEMINI_API_KEY when MATCHING_PROVIDER=gemini")

    async def find_candidates(
        self,
        *,
        shopee_title: str,
        image_url: str | None = None,
    ) -> list[AmazonCandidateMatch]:
        self._ensure_configured()
        title = shopee_title.strip()
        if not title:
            return []

        image: tuple[bytes, str] | None = None
        if image_url:
            image = await asyncio.to_thread(_fetch_image_bytes, image_url)

        prompt = _build_prompt(title, has_image=image is not None)
        max_retries = self._settings.gemini_max_retries
        min_interval = self._settings.gemini_min_interval_sec

        last_error: BaseException | None = None
        for attempt in range(1, max_retries + 1):
            await _wait_for_rate_limit(min_interval)
            try:
                raw = await asyncio.to_thread(
                    _call_gemini_sync,
                    api_key=self._settings.gemini_api_key,
                    model_name=self._settings.gemini_model,
                    prompt=prompt,
                    image=image,
                )
                return _parse_candidates_payload(raw)
            except GeminiConfigError:
                raise
            except Exception as exc:
                last_error = exc
                if not _is_retryable(exc) or attempt >= max_retries:
                    raise
                backoff = min_interval * (2 ** (attempt - 1))
                logger.warning(
                    "Gemini rate limit or transient error (attempt %s/%s), retry in %.1fs: %s",
                    attempt,
                    max_retries,
                    backoff,
                    exc,
                )
                await asyncio.sleep(backoff)

        if last_error is not None:
            raise last_error
        return []
