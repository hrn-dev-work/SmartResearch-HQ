"""Enqueue helpers for background jobs."""

from uuid import UUID

from arq import create_pool

from app.workers.settings import WorkerSettings


async def enqueue_research_job(job_id: UUID) -> None:
    redis = await create_pool(WorkerSettings.redis_settings())
    try:
        await redis.enqueue_job("process_research_job", str(job_id))
    finally:
        await redis.close()
