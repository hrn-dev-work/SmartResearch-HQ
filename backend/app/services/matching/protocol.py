from typing import Protocol

from app.services.matching.types import AmazonCandidateMatch


class CandidateMatcher(Protocol):
    async def find_candidates(
        self,
        *,
        shopee_title: str,
        image_url: str | None = None,
    ) -> list[AmazonCandidateMatch]:
        """Return ranked Amazon ASIN candidates for a Shopee item."""
