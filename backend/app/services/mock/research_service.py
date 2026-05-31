import re
from datetime import UTC, datetime
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
    def create_research(
        self, shopee_shop_url: str, seller_display_name: str | None
    ) -> CreateResearchResponse:
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

    def decide(
        self,
        item_id: UUID,
        candidate_id: UUID | None,
        rejected: bool,
        manual_asin: str | None = None,
    ) -> DecideReviewResponse:
        if rejected:
            fixtures.save_rejected_decision(item_id)
            return DecideReviewResponse(item_id=item_id, status="REJECTED", exported=False)

        if manual_asin is not None:
            normalized = manual_asin.strip().upper()
            if not re.fullmatch(r"B[A-Z0-9]{9}", normalized):
                raise ValueError("INVALID_ASIN")
            fixtures.save_manual_asin_decision(item_id, normalized)
            return DecideReviewResponse(item_id=item_id, status="APPROVED", exported=False)

        if candidate_id is None:
            raise ValueError("candidate_id or manual_asin required")

        fixtures.save_candidate_decision(item_id, candidate_id)
        return DecideReviewResponse(item_id=item_id, status="APPROVED", exported=False)

    def export_job(self, job_id: UUID) -> ExportJobResponse | None:
        job = fixtures.get_job(job_id)
        if job is None:
            return None

        items, _ = fixtures.get_items(job_id, 1, 1000)
        now = datetime.now(UTC)
        exported_item_ids: list[UUID] = []
        skipped = 0

        for item in items:
            if item.decision is None:
                skipped += 1
                continue
            if fixtures.is_rejected(item.item_id):
                skipped += 1
                continue
            if fixtures.is_exported(item.item_id):
                skipped += 1
                continue

            manual = fixtures.manual_asin_for(item.item_id)
            if manual:
                exported_item_ids.append(item.item_id)
                continue

            chosen = next(
                (c for c in item.candidates if c.candidate_id == item.decision),
                None,
            )
            if chosen is None:
                skipped += 1
                continue

            exported_item_ids.append(item.item_id)

        if exported_item_ids:
            fixtures.mark_exported(exported_item_ids, now)
            fixtures.set_job_status(job_id, JobStatus.EXPORTED)

        return ExportJobResponse(
            job_id=job_id,
            exported_count=len(exported_item_ids),
            skipped_count=skipped,
        )

    def run_pipeline(self, job_id: UUID, *, max_items: int = 20) -> None:
        raise NotImplementedError("MockResearchService does not run production pipeline")
