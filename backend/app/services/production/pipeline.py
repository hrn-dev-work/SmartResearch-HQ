"""Production job pipeline: scrape → match → persist."""

from datetime import UTC, datetime
from decimal import Decimal
from uuid import UUID

from app.config import MatchingProvider, get_settings
from app.core.status import JobStatus
from app.db.models import AmazonCandidate, JobItem, ResearchJob, Seller
from app.services.matching import get_candidate_matcher
from app.services.matching.amazon_search import AmazonSearchConfigError
from app.services.scraper.shopee_crawler import ScrapeBlockedError, fetch_sold_items
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload


async def _set_job_status(
    session: AsyncSession,
    job: ResearchJob,
    *,
    status: JobStatus,
    progress_pct: int,
    error_code: str | None = None,
    error_message: str | None = None,
) -> None:
    job.status = status.value
    job.progress_pct = progress_pct
    job.error_code = error_code
    job.error_message = error_message
    job.updated_at = datetime.now(UTC)
    if status in (JobStatus.AWAITING_REVIEW, JobStatus.SCRAPE_FAILED, JobStatus.AI_FAILED):
        if status == JobStatus.AWAITING_REVIEW:
            job.completed_at = datetime.now(UTC)
    await session.flush()


async def run_job_pipeline(session: AsyncSession, job_id: UUID, *, max_items: int = 20) -> None:
    settings = get_settings()
    matcher = get_candidate_matcher()

    result = await session.execute(
        select(ResearchJob)
        .where(ResearchJob.id == job_id)
        .options(selectinload(ResearchJob.seller))
    )
    job = result.scalar_one_or_none()
    if job is None:
        raise ValueError(f"Job not found: {job_id}")

    shop_url = job.seller.shopee_shop_url

    await _set_job_status(session, job, status=JobStatus.SCRAPING, progress_pct=10)
    await session.commit()

    try:
        scraped = await fetch_sold_items(shop_url, max_items=max_items)
    except ScrapeBlockedError as exc:
        await _set_job_status(
            session,
            job,
            status=JobStatus.SCRAPE_FAILED,
            progress_pct=100,
            error_code="SCRAPE_BLOCKED",
            error_message=str(exc),
        )
        await session.commit()
        return

    for index, item in enumerate(scraped):
        session.add(
            JobItem(
                job_id=job.id,
                shopee_item_id=item.shopee_item_id,
                title=item.title,
                image_url=item.image_url or "https://placehold.co/400x400?text=No+Image",
                sold_count=item.sold_count,
                price_display=item.price_display,
                scrape_metadata=item.metadata,
            )
        )
        job.progress_pct = 10 + int(30 * (index + 1) / max(len(scraped), 1))
    await session.flush()
    await _set_job_status(session, job, status=JobStatus.AI_INFERENCE, progress_pct=45)
    await session.commit()

    items_result = await session.execute(select(JobItem).where(JobItem.job_id == job.id))
    db_items = list(items_result.scalars().all())
    total = len(db_items)

    for index, db_item in enumerate(db_items):
        if settings.matching_provider == MatchingProvider.NONE:
            candidates = []
        else:
            try:
                candidates = await matcher.find_candidates(
                    shopee_title=db_item.title,
                    image_url=db_item.image_url,
                )
            except AmazonSearchConfigError as exc:
                await _set_job_status(
                    session,
                    job,
                    status=JobStatus.AI_FAILED,
                    progress_pct=100,
                    error_code="MATCHING_CONFIG",
                    error_message=str(exc),
                )
                await session.commit()
                return
            except Exception as exc:
                await _set_job_status(
                    session,
                    job,
                    status=JobStatus.AI_FAILED,
                    progress_pct=100,
                    error_code="AI_FAILED",
                    error_message=str(exc),
                )
                await session.commit()
                return

        for rank, match in enumerate(candidates[:3], start=1):
            session.add(
                AmazonCandidate(
                    job_item_id=db_item.id,
                    rank=rank,
                    asin=match.asin,
                    amazon_url=match.amazon_url,
                    title=match.title,
                    confidence=Decimal(str(match.confidence)),
                    reasoning=match.reasoning,
                    source=settings.matching_provider.value,
                )
            )
        progress = 45 + int(55 * (index + 1) / max(total, 1))
        job.progress_pct = progress
        await session.flush()

    await _set_job_status(session, job, status=JobStatus.AWAITING_REVIEW, progress_pct=100)
    await session.commit()


async def create_job_record(
    session: AsyncSession,
    *,
    shopee_shop_url: str,
    seller_display_name: str | None,
) -> ResearchJob:
    seller_result = await session.execute(
        select(Seller).where(Seller.shopee_shop_url == shopee_shop_url)
    )
    seller = seller_result.scalar_one_or_none()
    if seller is None:
        seller = Seller(shopee_shop_url=shopee_shop_url, display_name=seller_display_name)
        session.add(seller)
        await session.flush()
    elif seller_display_name and seller.display_name != seller_display_name:
        seller.display_name = seller_display_name

    job = ResearchJob(
        seller_id=seller.id,
        status=JobStatus.PENDING.value,
        progress_pct=0,
    )
    session.add(job)
    await session.flush()
    return job


async def count_job_items(session: AsyncSession, job_id: UUID) -> int:
    result = await session.execute(
        select(func.count()).select_from(JobItem).where(JobItem.job_id == job_id)
    )
    return int(result.scalar_one())
