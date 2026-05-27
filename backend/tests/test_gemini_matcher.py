"""Tests for GeminiMatcher (throttle, parse, config — no live API)."""

from __future__ import annotations

import asyncio
import time
from unittest.mock import AsyncMock, patch

import app.services.matching.gemini as gemini_module
import pytest
from app.config import Settings
from app.services.matching.gemini import (
    GeminiConfigError,
    GeminiMatcher,
    _parse_candidates_payload,
    _wait_for_rate_limit,
)


def test_parse_candidates_payload_valid() -> None:
    raw = """
    {
      "candidates": [
        {
          "asin": "B0DEMO0001",
          "title": "Wireless Earbuds",
          "confidence": 0.91,
          "reasoning": "Similar form factor"
        }
      ]
    }
    """
    matches = _parse_candidates_payload(raw)
    assert len(matches) == 1
    assert matches[0].asin == "B0DEMO0001"
    assert matches[0].confidence == 0.91


def test_parse_candidates_payload_skips_invalid_asin() -> None:
    raw = '{"candidates":[{"asin":"INVALID","title":"x","confidence":0.5}]}'
    assert _parse_candidates_payload(raw) == []


def test_gemini_matcher_requires_api_key() -> None:
    settings = Settings(
        gemini_api_key="",
        matching_provider="gemini",
    )
    matcher = GeminiMatcher(settings)

    async def run() -> None:
        await matcher.find_candidates(shopee_title="Test product")

    with pytest.raises(GeminiConfigError, match="GEMINI_API_KEY"):
        asyncio.run(run())


def test_wait_for_rate_limit_enforces_interval() -> None:
    async def run() -> None:
        gemini_module._rate_limiter = None
        gemini_module._last_request_at = 0.0

        await _wait_for_rate_limit(0.05)
        start = time.monotonic()
        await _wait_for_rate_limit(0.05)
        elapsed = time.monotonic() - start
        assert elapsed >= 0.04

    asyncio.run(run())


def test_find_candidates_calls_api_and_parses() -> None:
    settings = Settings(
        gemini_api_key="test-key",
        gemini_model="gemini-2.0-flash",
        gemini_min_interval_sec=0.0,
        gemini_max_retries=1,
    )
    matcher = GeminiMatcher(settings)
    payload = '{"candidates":[{"asin":"B0DEMO0002","title":"C","confidence":0.8}]}'

    async def run() -> None:
        with patch(
            "app.services.matching.gemini._call_gemini_sync",
            return_value=payload,
        ) as mock_call:
            matches = await matcher.find_candidates(
                shopee_title="USB-C Cable",
                image_url=None,
            )
        assert len(matches) == 1
        assert matches[0].asin == "B0DEMO0002"
        mock_call.assert_called_once()

    asyncio.run(run())


def test_find_candidates_retries_on_429() -> None:
    settings = Settings(
        gemini_api_key="test-key",
        gemini_min_interval_sec=0.0,
        gemini_max_retries=3,
    )
    matcher = GeminiMatcher(settings)
    payload = '{"candidates":[{"asin":"B0DEMO0003","title":"Fan","confidence":0.7}]}'
    calls = {"n": 0}

    def side_effect(**_kwargs: object) -> str:
        calls["n"] += 1
        if calls["n"] == 1:
            raise RuntimeError("429 Too Many Requests")
        return payload

    async def run() -> None:
        with (
            patch("app.services.matching.gemini._call_gemini_sync", side_effect=side_effect),
            patch("app.services.matching.gemini.asyncio.sleep", new_callable=AsyncMock),
        ):
            matches = await matcher.find_candidates(shopee_title="Mini Fan")
        assert len(matches) == 1
        assert calls["n"] == 2

    asyncio.run(run())
