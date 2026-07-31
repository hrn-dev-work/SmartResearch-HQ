"""Component integration: public API rate limit middleware."""

from app.config import get_settings
from app.core.rate_limit import reset_limiter
from app.main import app
from fastapi.testclient import TestClient

_PROBE = "/api/v1/research/00000000-0000-0000-0000-000000000001"


def test_rate_limit_returns_429_after_window_exhausted(monkeypatch) -> None:
    monkeypatch.setenv("RATE_LIMIT_ENABLED", "true")
    monkeypatch.setenv("RATE_LIMIT_REQUESTS", "3")
    monkeypatch.setenv("RATE_LIMIT_WINDOW_SEC", "60")
    get_settings.cache_clear()
    reset_limiter()

    client = TestClient(app)
    try:
        for _ in range(3):
            assert client.get(_PROBE).status_code in {200, 404}
        blocked = client.get(_PROBE)
        assert blocked.status_code == 429
        body = blocked.json()
        assert body["error"]["code"] == "RATE_LIMITED"
        assert "Retry-After" in blocked.headers
    finally:
        get_settings.cache_clear()
        reset_limiter()


def test_health_is_exempt_from_rate_limit(monkeypatch) -> None:
    monkeypatch.setenv("RATE_LIMIT_ENABLED", "true")
    monkeypatch.setenv("RATE_LIMIT_REQUESTS", "1")
    monkeypatch.setenv("RATE_LIMIT_WINDOW_SEC", "60")
    get_settings.cache_clear()
    reset_limiter()

    client = TestClient(app)
    try:
        assert client.get("/api/v1/health").status_code == 200
        assert client.get("/api/v1/health").status_code == 200
        assert client.get(_PROBE).status_code in {200, 404}
        assert client.get(_PROBE).status_code == 429
    finally:
        get_settings.cache_clear()
        reset_limiter()
