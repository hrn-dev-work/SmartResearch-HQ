"""
Optional multimodal matcher (Gemini image + text).

Deferred: API quota limits make this a fallback, not the default path.
"""

from app.config import Settings
from app.services.matching.types import AmazonCandidateMatch


class GeminiMatcher:
    def __init__(self, settings: Settings) -> None:
        self._settings = settings

    async def find_candidates(
        self,
        *,
        shopee_title: str,
        image_url: str | None = None,
    ) -> list[AmazonCandidateMatch]:
        raise NotImplementedError(
            "Gemini multimodal matching — optional Phase 2+ (MATCHING_PROVIDER=gemini)"
        )
