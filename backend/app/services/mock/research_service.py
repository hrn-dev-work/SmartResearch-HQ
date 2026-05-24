from uuid import UUID

from app.core.status import JobStatus
from app.schemas.research import (
    CreateResearchResponse,
    DecideReviewResponse,
    ExportJobResponse,
    ResearchJobResponse,
    ReviewItemsPageResponse,
)
from app.services.mock import fixtures


class MockResearchService:
    def create_research(self, shopee_shop_url: str, seller_display_name: str | None) -> CreateResearchResponse:
        job_id = fixtures.seed_demo_job(shopee_shop_url, seller_display_name)
        return CreateResearchResponse(
            job_id=job_id,
            status=JobStatus.AWAITING_REVIEW,
            progress_pct=100,
        )

    def get_job(self, job_id: UUID) -> ResearchJobResponse | None:
        return fixtures.get_job(job_id)

    def list_items(self, job_id: UUID, page: int, page_size: int) -> ReviewItemsPageResponse | None:
        if fixtures.get_job(job_id) is None:
            return None
        items, total = fixtures.get_items(job_id, page, page_size)
        return ReviewItemsPageResponse(items=items, page=page, page_size=page_size, total=total)

    def decide(self, item_id: UUID, candidate_id: UUID | None, rejected: bool) -> DecideReviewResponse:
        fixtures.save_decision(item_id, None if rejected else candidate_id)
        status = "REJECTED" if rejected else "APPROVED"
        return DecideReviewResponse(item_id=item_id, status=status, exported=False)

    def export_job(self, job_id: UUID) -> ExportJobResponse | None:
        job = fixtures.get_job(job_id)
        if job is None:
            return None
        items, _ = fixtures.get_items(job_id, 1, 1000)
        exported = sum(1 for i in items if i.decision is not None)
        skipped = len(items) - exported
        return ExportJobResponse(job_id=job_id, exported_count=exported, skipped_count=skipped)
