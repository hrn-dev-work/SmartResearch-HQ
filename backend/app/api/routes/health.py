from fastapi import APIRouter

from app.config import AppMode, get_settings
from app.core.redis import ping_redis
from app.schemas.common import HealthResponse

router = APIRouter(tags=["health"])


@router.get("/health", response_model=HealthResponse)
async def health() -> HealthResponse:
    settings = get_settings()
    redis_status: str | None = None
    if settings.app_mode == AppMode.PRODUCTION:
        try:
            redis_status = "ok" if await ping_redis() else "unavailable"
        except OSError:
            redis_status = "unavailable"

    return HealthResponse(
        status="ok",
        mode=settings.app_mode.value,
        matching_provider=settings.matching_provider.value,
        redis=redis_status,
    )
