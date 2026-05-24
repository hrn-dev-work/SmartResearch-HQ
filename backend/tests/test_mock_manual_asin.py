from fastapi.testclient import TestClient

from app.main import app
from app.services.mock import fixtures

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
    assert decided.decision == item_id


def test_decide_manual_asin_invalid_format() -> None:
    job_id = fixtures.seed_demo_job("https://shopee.sg/shop/invalid-asin", "Invalid")
    items, _ = fixtures.get_items(job_id, 1, 20)
    item_id = items[0].item_id

    response = client.post(
        f"/api/v1/review/{item_id}/decide",
        json={"manual_asin": "INVALID"},
    )
    assert response.status_code == 400
    assert response.json()["detail"]["error"]["code"] == "INVALID_ASIN"
