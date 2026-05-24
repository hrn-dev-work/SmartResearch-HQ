from unittest.mock import AsyncMock, patch

from fastapi.testclient import TestClient

from app.config import get_settings
from app.main import app

client = TestClient(app)


def test_health_omits_redis_in_portfolio_mode() -> None:
    get_settings.cache_clear()
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    assert response.json().get("redis") is None


@patch("app.api.routes.health.ping_redis", new_callable=AsyncMock, return_value=True)
def test_health_reports_redis_ok_in_production(mock_ping: AsyncMock, monkeypatch) -> None:
    monkeypatch.setenv("APP_MODE", "production")
    get_settings.cache_clear()
    response = client.get("/api/v1/health")
    get_settings.cache_clear()
    assert response.status_code == 200
    assert response.json()["redis"] == "ok"
    mock_ping.assert_awaited_once()
