"""In-memory sliding-window rate limit for the public API (no Redis)."""

from __future__ import annotations

import time
from collections import defaultdict, deque
from threading import Lock

from app.config import get_settings
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import JSONResponse, Response

EXEMPT_PREFIXES = ("/api/v1/health",)


class SlidingWindowLimiter:
    """Track request timestamps per key within a fixed window."""

    def __init__(self) -> None:
        self._hits: dict[str, deque[float]] = defaultdict(deque)
        self._lock = Lock()

    def reset(self) -> None:
        with self._lock:
            self._hits.clear()

    def allow(self, key: str, *, limit: int, window_sec: float) -> tuple[bool, float]:
        """Return (allowed, retry_after_sec). retry_after is 0 when allowed."""
        now = time.monotonic()
        cutoff = now - window_sec
        with self._lock:
            bucket = self._hits[key]
            while bucket and bucket[0] <= cutoff:
                bucket.popleft()
            if len(bucket) >= limit:
                retry_after = max(0.0, window_sec - (now - bucket[0]))
                return False, retry_after
            bucket.append(now)
            return True, 0.0


_limiter = SlidingWindowLimiter()


def get_limiter() -> SlidingWindowLimiter:
    return _limiter


def reset_limiter() -> None:
    _limiter.reset()


def client_ip(request: Request) -> str:
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip() or "unknown"
    if request.client and request.client.host:
        return request.client.host
    return "unknown"


def is_exempt(path: str) -> bool:
    return any(path == p or path.startswith(p + "/") for p in EXEMPT_PREFIXES)


class RateLimitMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> Response:
        settings = get_settings()
        if not settings.rate_limit_enabled or is_exempt(request.url.path):
            return await call_next(request)

        allowed, retry_after = _limiter.allow(
            client_ip(request),
            limit=settings.rate_limit_requests,
            window_sec=float(settings.rate_limit_window_sec),
        )
        if not allowed:
            return JSONResponse(
                status_code=429,
                content={
                    "error": {
                        "code": "RATE_LIMITED",
                        "message": "Too many requests. Try again shortly.",
                        "details": {},
                    }
                },
                headers={"Retry-After": str(max(1, int(retry_after + 0.999)))},
            )
        return await call_next(request)
