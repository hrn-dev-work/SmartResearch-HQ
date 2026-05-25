from uuid import UUID

from app.core.status import JobStatus
from app.db.models import JobItem, ResearchJob, ReviewDecision
from app.schemas.research import (
    AmazonCandidateResponse,
    CreateResearchResponse,
    DecideReviewResponse,
    ExportJobResponse,
    JobError,
    ResearchJobResponse,
    ReviewItemResponse,
    ReviewItemsPageResponse,
    SellerSummary,
)
from app.services.production.pipeline import create_job_record, run_job_pipeline
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload


def _asin_pattern_ok(asin: str) -> bool:
    import re

    return bool(re.fullmatch(r"B[A-Z0-9]{9}", asin.upper()))


class ProductionResearchService:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def create_research(
        self, shopee_shop_url: str, seller_display_name: str | None
    ) -> CreateResearchResponse:
        job = await create_job_record(
            self._session,
            shopee_shop_url=shopee_shop_url,
            seller_display_name=seller_display_name,
        )
        await self._session.commit()
        return CreateResearchResponse(
            job_id=job.id,
            status=JobStatus(job.status),
            progress_pct=job.progress_pct,
        )

    async def get_job(self, job_id: UUID) -> ResearchJobResponse | None:
        result = await self._session.execute(
            select(ResearchJob)
            .where(ResearchJob.id == job_id)
            .options(selectinload(ResearchJob.seller), selectinload(ResearchJob.items))
        )
        job = result.scalar_one_or_none()
        if job is None:
            return None
        error = None
        if job.error_code:
            error = JobError(code=job.error_code, message=job.error_message or job.error_code)
        return ResearchJobResponse(
            job_id=job.id,
            status=JobStatus(job.status),
            progress_pct=job.progress_pct,
            seller=SellerSummary(
                shopee_shop_url=job.seller.shopee_shop_url,
                display_name=job.seller.display_name,
            ),
            item_count=len(job.items),
            error=error,
            created_at=job.created_at,
            updated_at=job.updated_at,
        )

    async def list_items(
        self, job_id: UUID, page: int, page_size: int
    ) -> ReviewItemsPageResponse | None:
        job_exists = await self._session.execute(
            select(ResearchJob.id).where(ResearchJob.id == job_id)
        )
        if job_exists.scalar_one_or_none() is None:
            return None

        total_result = await self._session.execute(
            select(func.count()).select_from(JobItem).where(JobItem.job_id == job_id)
        )
        total = int(total_result.scalar_one())

        result = await self._session.execute(
            select(JobItem)
            .where(JobItem.job_id == job_id)
            .options(
                selectinload(JobItem.candidates),
                selectinload(JobItem.decision),
            )
            .order_by(JobItem.created_at)
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        items = result.scalars().all()
        responses: list[ReviewItemResponse] = []
        for item in items:
            decision_id = None
            if item.decision and item.decision.chosen_candidate_id:
                decision_id = item.decision.chosen_candidate_id
            elif item.decision and item.decision.manual_asin:
                decision_id = item.decision.id
            responses.append(
                ReviewItemResponse(
                    item_id=item.id,
                    title=item.title,
                    image_url=item.image_url,
                    sold_count=item.sold_count,
                    candidates=[
                        AmazonCandidateResponse(
                            candidate_id=c.id,
                            rank=c.rank,
                            asin=c.asin,
                            amazon_url=c.amazon_url,
                            title=c.title,
                            confidence=float(c.confidence),
                        )
                        for c in sorted(item.candidates, key=lambda x: x.rank)
                    ],
                    decision=decision_id,
                )
            )
        return ReviewItemsPageResponse(items=responses, page=page, page_size=page_size, total=total)

    async def decide(
        self,
        item_id: UUID,
        candidate_id: UUID | None,
        rejected: bool,
        manual_asin: str | None = None,
    ) -> DecideReviewResponse:
        result = await self._session.execute(
            select(JobItem)
            .where(JobItem.id == item_id)
            .options(selectinload(JobItem.decision), selectinload(JobItem.candidates))
        )
        item = result.scalar_one_or_none()
        if item is None:
            raise ValueError(f"Item not found: {item_id}")

        if item.decision:
            status = "REJECTED" if item.decision.rejected else "APPROVED"
            return DecideReviewResponse(item_id=item_id, status=status, exported=False)

        if rejected:
            self._session.add(
                ReviewDecision(job_item_id=item.id, rejected=True, chosen_candidate_id=None)
            )
            await self._session.commit()
            return DecideReviewResponse(item_id=item_id, status="REJECTED", exported=False)

        if manual_asin:
            normalized = manual_asin.strip().upper()
            if not _asin_pattern_ok(normalized):
                raise ValueError("INVALID_ASIN")
            if candidate_id is not None:
                raise ValueError("candidate_id and manual_asin are mutually exclusive")
            self._session.add(
                ReviewDecision(
                    job_item_id=item.id,
                    manual_asin=normalized,
                    rejected=False,
                )
            )
            await self._session.commit()
            return DecideReviewResponse(item_id=item_id, status="APPROVED", exported=False)

        if candidate_id is None:
            raise ValueError("candidate_id or manual_asin required")

        valid_ids = {c.id for c in item.candidates}
        if candidate_id not in valid_ids:
            raise ValueError("Invalid candidate_id")

        self._session.add(
            ReviewDecision(
                job_item_id=item.id,
                chosen_candidate_id=candidate_id,
                rejected=False,
            )
        )
        await self._session.commit()
        return DecideReviewResponse(item_id=item_id, status="APPROVED", exported=False)

    async def export_job(self, job_id: UUID) -> ExportJobResponse | None:
        job = await self.get_job(job_id)
        if job is None:
            return None
        result = await self._session.execute(
            select(JobItem).where(JobItem.job_id == job_id).options(selectinload(JobItem.decision))
        )
        items = result.scalars().all()
        exported = sum(1 for i in items if i.decision and not i.decision.rejected)
        skipped = len(items) - exported
        return ExportJobResponse(job_id=job_id, exported_count=exported, skipped_count=skipped)

    async def run_pipeline(self, job_id: UUID, *, max_items: int = 20) -> None:
        await run_job_pipeline(self._session, job_id, max_items=max_items)
