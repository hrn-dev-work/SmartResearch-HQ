from app.config import get_settings
from app.main import app
from fastapi.testclient import TestClient

client = TestClient(app)


def test_health_omits_redis_in_portfolio_mode() -> None:
    get_settings.cache_clear()
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    assert response.json().get("redis") is None


def test_health_omits_redis_in_production_mode(monkeypatch) -> None:
    monkeypatch.setenv("APP_MODE", "production")
    get_settings.cache_clear()
    response = client.get("/api/v1/health")
    get_settings.cache_clear()
    assert response.status_code == 200
    data = response.json()
    assert data["mode"] == "production"
    assert data.get("redis") is None
