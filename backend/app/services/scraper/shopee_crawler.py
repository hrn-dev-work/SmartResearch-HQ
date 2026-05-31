"""
Playwright-based Shopee crawler.

Extracts product listings from a seller shop page. On CAPTCHA / IP block,
raises ScrapeBlockedError for retry/DLQ handling.
"""

import json
import re
from dataclasses import dataclass, field
from typing import Any
from urllib.parse import urlparse

from playwright.async_api import async_playwright

CAPTCHA_MARKERS = ("captcha", "verify", "robot", "security check")
MAX_ITEMS_DEFAULT = 20


@dataclass
class ShopeeSoldItem:
    shopee_item_id: str
    title: str
    image_url: str
    sold_count: int | None
    price_display: str | None
    shopee_item_url: str = ""
    metadata: dict[str, Any] = field(default_factory=dict)


def build_shopee_item_url(shop_url: str, item_id: str, shop_id: str | None = None) -> str:
    """Build a product URL from shop context and item id (best-effort)."""
    parsed = urlparse(shop_url)
    if not parsed.scheme or not parsed.netloc:
        return ""
    base = f"{parsed.scheme}://{parsed.netloc}"
    resolved_shop_id = shop_id
    if not resolved_shop_id:
        match = re.search(r"/shop/(\d+)", shop_url)
        if match:
            resolved_shop_id = match.group(1)
    if resolved_shop_id:
        return f"{base}/product-i.{resolved_shop_id}.{item_id}"
    return f"{base}/product/{item_id}"


class ScrapeBlockedError(Exception):
    """Raised when CAPTCHA or rate limit blocks scraping."""


def _image_url_from_id(image_hash: str) -> str:
    if not image_hash:
        return ""
    if image_hash.startswith("http"):
        return image_hash
    return f"https://cf.shopee.sg/file/{image_hash}"


def _parse_item_dict(raw: dict[str, Any]) -> ShopeeSoldItem | None:
    item_id = raw.get("itemid") or raw.get("item_id") or raw.get("id")
    if item_id is None:
        return None
    basic = raw.get("item_basic") or raw.get("item_card") or raw
    title = basic.get("name") or basic.get("title") or raw.get("name") or raw.get("title") or ""
    if not str(title).strip():
        return None
    image = (
        basic.get("image") or basic.get("thumb") or raw.get("image") or raw.get("image_url") or ""
    )
    if isinstance(image, list) and image:
        image = image[0]
    sold = basic.get("sold") or basic.get("historical_sold") or raw.get("sold")
    price = basic.get("price") or raw.get("price")
    shop_id = raw.get("shopid") or basic.get("shopid") or raw.get("shop_id")
    price_display = None
    if isinstance(price, int):
        price_display = f"{price / 100000:.2f}"
    elif price is not None:
        price_display = str(price)
    return ShopeeSoldItem(
        shopee_item_id=str(item_id),
        title=str(title).strip(),
        image_url=_image_url_from_id(str(image)) if image else "",
        sold_count=int(sold) if sold is not None else None,
        price_display=price_display,
        metadata={
            "raw_keys": list(raw.keys())[:20],
            "shop_id": str(shop_id) if shop_id is not None else None,
        },
    )


def _extract_items_from_payload(payload: Any, found: dict[str, ShopeeSoldItem]) -> None:
    if isinstance(payload, dict):
        itemid = payload.get("itemid") or payload.get("item_id")
        if itemid is not None and ("name" in payload or "title" in payload):
            parsed = _parse_item_dict(payload)
            if parsed:
                found[parsed.shopee_item_id] = parsed
        for value in payload.values():
            _extract_items_from_payload(value, found)
    elif isinstance(payload, list):
        for entry in payload:
            _extract_items_from_payload(entry, found)


async def _detect_blocked(page) -> None:
    title = (await page.title()).lower()
    body_text = (await page.inner_text("body")).lower()[:2000]
    if any(marker in title or marker in body_text for marker in CAPTCHA_MARKERS):
        raise ScrapeBlockedError("CAPTCHA or verification page detected")


async def fetch_sold_items(
    shop_url: str,
    *,
    headless: bool = True,
    max_items: int = MAX_ITEMS_DEFAULT,
    timeout_ms: int = 60_000,
) -> list[ShopeeSoldItem]:
    parsed = urlparse(shop_url)
    if not parsed.scheme or not parsed.netloc:
        raise ValueError(f"Invalid shop URL: {shop_url}")

    collected: dict[str, ShopeeSoldItem] = {}

    async with async_playwright() as playwright:
        browser = await playwright.chromium.launch(headless=headless)
        context = await browser.new_context(
            user_agent=(
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                "(KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
            ),
            locale="en-SG",
        )
        page = await context.new_page()

        async def on_response(response) -> None:
            if response.status != 200:
                return
            url = response.url.lower()
            if "shopee" not in url:
                return
            if not any(token in url for token in ("shop", "item", "search", "recommend", "rcmd")):
                return
            try:
                payload = await response.json()
            except Exception:
                return
            _extract_items_from_payload(payload, collected)

        page.on("response", on_response)
        try:
            await page.goto(shop_url, wait_until="domcontentloaded", timeout=timeout_ms)
            await page.wait_for_timeout(3000)
            await _detect_blocked(page)

            # Scroll to load lazy listings
            for _ in range(3):
                await page.mouse.wheel(0, 1200)
                await page.wait_for_timeout(1500)

            html = await page.content()
            for match in re.finditer(
                r"<script[^>]*type=\"application/json\"[^>]*>(.*?)</script>", html, re.S
            ):
                try:
                    payload = json.loads(match.group(1))
                except json.JSONDecodeError:
                    continue
                _extract_items_from_payload(payload, collected)
        finally:
            await context.close()
            await browser.close()

    items = list(collected.values())[:max_items]
    for item in items:
        shop_id = item.metadata.get("shop_id")
        item.shopee_item_url = build_shopee_item_url(
            shop_url, item.shopee_item_id, str(shop_id) if shop_id else None
        )
    if not items:
        raise ScrapeBlockedError(
            "No items extracted — page may have changed, require login, or block automation"
        )
    return items
