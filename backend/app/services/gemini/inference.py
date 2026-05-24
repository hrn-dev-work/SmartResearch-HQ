"""
Backward-compatible shim — use app.services.matching instead.

Gemini multimodal matching is optional (MATCHING_PROVIDER=gemini).
"""

from app.config import get_settings
from app.services.matching.gemini import GeminiMatcher
from app.services.matching.types import AmazonCandidateMatch

AmazonMatch = AmazonCandidateMatch


async def infer_amazon_matches(
    *,
    shopee_title: str,
    image_url: str,
    api_key: str,
    model: str,
) -> list[AmazonCandidateMatch]:
    """Deprecated: prefer get_candidate_matcher() from app.services.matching."""
    _ = api_key, model
    matcher = GeminiMatcher(settings=get_settings())
    return await matcher.find_candidates(shopee_title=shopee_title, image_url=image_url)
