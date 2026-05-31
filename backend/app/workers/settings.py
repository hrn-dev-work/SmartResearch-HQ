"""ARQ worker settings and job handlers."""

import logging
from urllib.parse import urlparse
from uuid import UUID

from app.config import get_settings
from app.db.models import ResearchJob
from app.db.session import SessionLocal
from app.services.production.errors import PipelineRetriableError
from app.services.production.pipeline import run_job_pipeline
from app.workers.dlq import push_job_to_dlq
from arq.connections import RedisSettings
from arq.jobs import Job
from sqlalchemy import select

logger = logging.getLogger(__name__)

MAX_RETRIES = 3
BASE_RETRY_DELAY_SEC = 30


def retry_delay(job_try: int) -> int:
    """Exponential backoff: 30s, 60s, capped at 300s."""
    return min(BASE_RETRY_DELAY_SEC * (2 ** max(job_try - 1, 0)), 300)


async def _load_job(session, job_id: UUID) -> ResearchJob | None:
    result = await session.execute(select(ResearchJob).where(ResearchJob.id == job_id))
    return result.scalar_one_or_none()


async def process_research_job(ctx: dict, job_id: str) -> None:
    job_uuid = UUID(job_id)
    job_try = int(ctx.get("job_try", 1))

    async with SessionLocal() as session:
        job = await _load_job(session, job_uuid)
        if job is None:
            raise ValueError(f"Job not found: {job_id}")
        job.retry_count = max(job_try - 1, 0)
        await session.commit()

        await run_job_pipeline(session, job_uuid)


async def on_job_failure(ctx: dict, job_id: str, job: Job, exc: BaseException) -> None:
    job_uuid = UUID(job_id)
    job_try = int(ctx.get("job_try", job.job_try if job else MAX_RETRIES))

    status = "UNKNOWN"
    error_code = "WORKER_FAILED"
    error_message = str(exc)

    async with SessionLocal() as session:
        db_job = await _load_job(session, job_uuid)
        if db_job is None:
            logger.error("DLQ: job %s not found after failure", job_id)
            return

        db_job.retry_count = job_try
        status = db_job.status
        error_code = db_job.error_code or "WORKER_FAILED"
        error_message = db_job.error_message or str(exc)
        await session.commit()

    try:
        await push_job_to_dlq(
            job_uuid,
            error_code=error_code,
            error_message=error_message,
            retry_count=job_try,
            status=status,
        )
    except Exception:
        logger.exception("Failed to push job %s to DLQ", job_id)
        return

    logger.warning(
        "Job %s moved to DLQ after %s attempt(s): %s — %s",
        job_id,
        job_try,
        error_code,
        error_message,
    )


async def startup(ctx: dict) -> None:
    ctx["settings"] = get_settings()


class WorkerSettings:
    functions = [process_research_job]
    on_startup = startup
    on_job_failure = on_job_failure
    max_tries = MAX_RETRIES
    retry_jobs = PipelineRetriableError
    retry_delay = retry_delay
    job_timeout = 600

    @staticmethod
    def redis_settings() -> RedisSettings:
        url = get_settings().redis_url
        parsed = urlparse(url)
        db = int(parsed.path.lstrip("/") or 0)
        return RedisSettings(
            host=parsed.hostname or "localhost",
            port=parsed.port or 6379,
            database=db,
            password=parsed.password,
        )
