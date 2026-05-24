"""ARQ worker settings and job handlers."""

from urllib.parse import urlparse
from uuid import UUID

from app.config import get_settings
from app.db.session import SessionLocal
from app.services.production.pipeline import run_job_pipeline
from arq.connections import RedisSettings

MAX_RETRIES = 3


async def process_research_job(_ctx: dict, job_id: str) -> None:
    async with SessionLocal() as session:
        await run_job_pipeline(session, UUID(job_id))


async def startup(ctx: dict) -> None:
    ctx["settings"] = get_settings()


class WorkerSettings:
    functions = [process_research_job]
    on_startup = startup
    max_tries = MAX_RETRIES
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
