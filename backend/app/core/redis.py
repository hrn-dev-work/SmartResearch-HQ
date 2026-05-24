"""Redis connectivity helpers (production / ARQ)."""

from redis.asyncio import Redis

from app.config import get_settings


async def ping_redis() -> bool:
    """Return True when Redis responds to PING."""
    settings = get_settings()
    client = Redis.from_url(settings.redis_url)
    try:
        return bool(await client.ping())
    finally:
        await client.aclose()
