"""Amazon PA-API 5.0 title search matcher."""

import asyncio
import re
from functools import partial

from app.config import Settings, get_settings
from app.services.matching.types import AmazonCandidateMatch


class AmazonSearchConfigError(Exception):
    """PA-API credentials are missing or invalid."""


def normalize_search_title(title: str, *, max_len: int = 120) -> str:
    cleaned = re.sub(r"[^\w\s\-]", " ", title, flags=re.UNICODE)
    return " ".join(cleaned.split())[:max_len]


def _paapi_host(region: str) -> str:
    mapping = {
        "us-east-1": "webservices.amazon.com",
        "eu-west-1": "webservices.amazon.co.uk",
        "us-west-2": "webservices.amazon.com",
    }
    return mapping.get(region, "webservices.amazon.com")


def _search_sync(
    *,
    keywords: str,
    access_key: str,
    secret_key: str,
    partner_tag: str,
    region: str,
    item_count: int,
) -> list[AmazonCandidateMatch]:
    try:
        from paapi5_python_sdk.api.default_api import DefaultApi
        from paapi5_python_sdk.api_client import ApiClient
        from paapi5_python_sdk.configuration import Configuration
        from paapi5_python_sdk.models.partner_type import PartnerType
        from paapi5_python_sdk.models.search_items_request import SearchItemsRequest
        from paapi5_python_sdk.models.search_items_resource import SearchItemsResource
        from paapi5_python_sdk.rest import ApiException
    except ImportError as exc:
        raise AmazonSearchConfigError(
            "Install paapi5-python-sdk-repack (see backend/requirements.txt)"
        ) from exc

    configuration = Configuration(
        access_key=access_key,
        secret_key=secret_key,
        host=_paapi_host(region),
        region=region,
    )
    api = DefaultApi(ApiClient(configuration))
    request = SearchItemsRequest(
        partner_tag=partner_tag,
        partner_type=PartnerType.ASSOCIATES,
        keywords=keywords,
        search_index="All",
        item_count=item_count,
        resources=[
            SearchItemsResource.ITEMINFO_TITLE,
            SearchItemsResource.ITEMINFO_BYLINEINFO,
        ],
    )
    try:
        response = api.search_items(request)
    except ApiException as exc:
        raise RuntimeError(f"Amazon PA-API error: {exc}") from exc

    if response.search_result is None or not response.search_result.items:
        return []

    matches: list[AmazonCandidateMatch] = []
    for index, item in enumerate(response.search_result.items, start=1):
        asin = item.asin
        if not asin:
            continue
        item_title = ""
        if item.item_info and item.item_info.title and item.item_info.title.display_value:
            item_title = item.item_info.title.display_value
        confidence = max(0.5, round(0.95 - (index - 1) * 0.08, 2))
        matches.append(
            AmazonCandidateMatch(
                asin=asin,
                amazon_url=f"https://www.amazon.com/dp/{asin}",
                title=item_title or keywords,
                confidence=confidence,
                reasoning=f"PA-API keyword rank {index}",
            )
        )
    return matches


class AmazonSearchMatcher:
    def __init__(self, settings: Settings | None = None) -> None:
        self._settings = settings or get_settings()

    def _ensure_configured(self) -> None:
        if not (
            self._settings.amazon_paapi_access_key
            and self._settings.amazon_paapi_secret_key
            and self._settings.amazon_paapi_partner_tag
        ):
            raise AmazonSearchConfigError(
                "Set AMAZON_PAAPI_ACCESS_KEY, AMAZON_PAAPI_SECRET_KEY, AMAZON_PAAPI_PARTNER_TAG"
            )

    async def find_candidates(
        self,
        *,
        shopee_title: str,
        image_url: str | None = None,
    ) -> list[AmazonCandidateMatch]:
        _ = image_url
        self._ensure_configured()
        keywords = normalize_search_title(shopee_title)
        if not keywords:
            return []
        fn = partial(
            _search_sync,
            keywords=keywords,
            access_key=self._settings.amazon_paapi_access_key,
            secret_key=self._settings.amazon_paapi_secret_key,
            partner_tag=self._settings.amazon_paapi_partner_tag,
            region=self._settings.amazon_paapi_region,
            item_count=3,
        )
        return await asyncio.to_thread(fn)
