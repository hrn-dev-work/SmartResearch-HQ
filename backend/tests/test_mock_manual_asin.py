from unittest.mock import Mock

from app.api.deps import get_research_service
from app.config import get_settings
from app.main import app
from app.services.mock import fixtures
from app.services.production.research_service import ProductionResearchService
from fastapi.testclient import TestClient
from sqlalchemy.ext.asyncio import AsyncSession

client = TestClient(app)


def test_decide_manual_asin_in_portfolio_mode() -> None:
    job_id = fixtures.seed_demo_job("https://shopee.sg/shop/manual-test", "Manual ASIN Shop")
    items, _ = fixtures.get_items(job_id, 1, 20)
    no_candidate = next(i for i in items if len(i.candidates) == 0)
    item_id = no_candidate.item_id

    response = client.post(
        f"/api/v1/review/{item_id}/decide",
        json={"manual_asin": "B012345678"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "APPROVED"

    updated, _ = fixtures.get_items(job_id, 1, 20)
    decided = next(i for i in updated if i.item_id == item_id)
    assert decided.decision is not None


def test_decide_manual_asin_invalid_format_in_portfolio_mode() -> None:
    job_id = fixtures.seed_demo_job("https://shopee.sg/shop/invalid-asin", "Invalid")
    items, _ = fixtures.get_items(job_id, 1, 20)
    item_id = items[0].item_id

    response = client.post(
        f"/api/v1/review/{item_id}/decide",
        json={"manual_asin": "INVALID"},
    )
    assert response.status_code == 400
    assert response.json()["detail"]["error"]["code"] == "INVALID_ASIN"


def test_decide_manual_asin_invalid_format_in_production_mode() -> None:
    session = Mock(spec=AsyncSession)

    class InvalidAsinService(ProductionResearchService):
        async def decide(
            self,
            item_id,
            candidate_id,
            rejected,
            manual_asin=None,
        ):
            raise ValueError("INVALID_ASIN")

    async def override_service():
        return InvalidAsinService(session)

    app.dependency_overrides[get_research_service] = override_service
    try:
        job_id = fixtures.seed_demo_job("https://shopee.sg/shop/invalid-asin", "Invalid")
        items, _ = fixtures.get_items(job_id, 1, 20)
        item_id = items[0].item_id

        response = client.post(
            f"/api/v1/review/{item_id}/decide",
            json={"manual_asin": "INVALID"},
        )
        assert response.status_code == 400
        assert response.json()["detail"]["error"]["code"] == "INVALID_ASIN"
    finally:
        app.dependency_overrides.clear()
        get_settings.cache_clear()
