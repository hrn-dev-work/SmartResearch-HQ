from app.main import app
from fastapi.testclient import TestClient

client = TestClient(app)


def test_health_returns_portfolio_mock() -> None:
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["mode"] == "portfolio"
    assert data["matching_provider"] == "amazon_search"
