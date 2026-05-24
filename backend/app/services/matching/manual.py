"""No automatic candidates — reviewer enters ASIN manually in the UI."""

from app.services.matching.types import AmazonCandidateMatch


class ManualMatcher:
    async def find_candidates(
        self,
        *,
        shopee_title: str,
        image_url: str | None = None,
    ) -> list[AmazonCandidateMatch]:
        return []
