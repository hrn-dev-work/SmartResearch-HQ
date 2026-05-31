"""Mock/production API contract tests (portfolio mode)."""

from app.main import app
from app.services.mock import fixtures
from app.services.mock.research_service import MockResearchService
from fastapi.testclient import TestClient

client = TestClient(app)


def test_portfolio_research_e2e_flow() -> None:
    """Single-shot smoke: create → review → export (portfolio)."""
    create = client.post(
        "/api/v1/research",
        json={
            "shopee_shop_url": "https://shopee.sg/shop/e2e-flow",
            "seller_display_name": "E2E",
        },
    )
    assert create.status_code == 201
    job_id = create.json()["job_id"]

    items = client.get(f"/api/v1/research/{job_id}/items")
    assert items.status_code == 200
    first = items.json()["items"][0]
    assert first["shopee_item_url"]

    decide = client.post(
        f"/api/v1/review/{first['item_id']}/decide",
        json={"candidate_id": first["candidates"][0]["candidate_id"]},
    )
    assert decide.status_code == 200

    export = client.post(f"/api/v1/research/{job_id}/export")
    assert export.status_code == 202
    assert export.json()["exported_count"] == 1

    job = client.get(f"/api/v1/research/{job_id}")
    assert job.json()["status"] == "EXPORTED"


def test_reject_sets_decision_marker() -> None:
    job_id = fixtures.seed_demo_job("https://shopee.sg/shop/reject-test", "Reject Shop")
    items, _ = fixtures.get_items(job_id, 1, 20)
    item = items[0]

    response = client.post(
        f"/api/v1/review/{item.item_id}/decide",
        json={"rejected": True},
    )
    assert response.status_code == 200
    assert response.json()["status"] == "REJECTED"

    updated, _ = fixtures.get_items(job_id, 1, 20)
    row = next(i for i in updated if i.item_id == item.item_id)
    assert row.decision is not None


def test_export_skips_rejected_and_counts_approved() -> None:
    job_id = fixtures.seed_demo_job("https://shopee.sg/shop/export-test", "Export Shop")
    items, _ = fixtures.get_items(job_id, 1, 20)
    approved = items[0]
    rejected = items[1]
    candidate_id = approved.candidates[0].candidate_id

    client.post(
        f"/api/v1/review/{approved.item_id}/decide",
        json={"candidate_id": str(candidate_id)},
    )
    client.post(
        f"/api/v1/review/{rejected.item_id}/decide",
        json={"rejected": True},
    )

    first = client.post(f"/api/v1/research/{job_id}/export")
    assert first.status_code == 202
    assert first.json()["exported_count"] == 1
    assert first.json()["skipped_count"] == 3

    second = client.post(f"/api/v1/research/{job_id}/export")
    assert second.json()["exported_count"] == 0
    assert second.json()["skipped_count"] == 4


def test_review_items_include_shopee_urls() -> None:
    job_id = fixtures.seed_demo_job("https://shopee.sg/shop/123456", "URL Shop")
    response = client.get(f"/api/v1/research/{job_id}/items")
    assert response.status_code == 200
    item = response.json()["items"][0]
    assert item["shopee_item_url"].startswith("https://shopee.sg/product-i.123456.")
    assert item["shopee_item_id"]


def test_decision_marker_candidate_vs_manual() -> None:
    service = MockResearchService()
    job = service.create_research("https://shopee.sg/shop/marker", None)
    page = service.list_items(job.job_id, 1, 20)
    assert page is not None
    manual_item = next(i for i in page.items if len(i.candidates) == 0)
    service.decide(manual_item.item_id, None, False, manual_asin="B012345678")
    refreshed = service.list_items(job.job_id, 1, 20)
    assert refreshed is not None
    row = next(i for i in refreshed.items if i.item_id == manual_item.item_id)
    assert row.decision is not None
