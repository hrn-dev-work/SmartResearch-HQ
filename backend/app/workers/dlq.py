"""Dead-letter queue for research jobs that exhaust retries."""

from __future__ import annotations

import json
from datetime import UTC, datetime
from typing import Any
from urllib.parse import urlparse
from uuid import UUID

from app.config import get_settings
from arq.connections import ArqRedis, RedisSettings, create_pool

DLQ_KEY = "smartresearch:dlq:research_jobs"


def _redis_settings() -> RedisSettings:
    url = get_settings().redis_url
    parsed = urlparse(url)
    db = int(parsed.path.lstrip("/") or 0)
    return RedisSettings(
        host=parsed.hostname or "localhost",
        port=parsed.port or 6379,
        database=db,
        password=parsed.password,
    )


async def _redis_pool() -> ArqRedis:
    return await create_pool(_redis_settings())


async def push_job_to_dlq(
    job_id: UUID,
    *,
    error_code: str,
    error_message: str,
    retry_count: int,
    status: str,
) -> None:
    payload: dict[str, Any] = {
        "job_id": str(job_id),
        "status": status,
        "error_code": error_code,
        "error_message": error_message,
        "retry_count": retry_count,
        "failed_at": datetime.now(UTC).isoformat(),
    }
    redis = await _redis_pool()
    try:
        await redis.lpush(DLQ_KEY, json.dumps(payload, ensure_ascii=False))
    finally:
        await redis.close()
