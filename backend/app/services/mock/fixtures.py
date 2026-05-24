from datetime import UTC, datetime
from uuid import UUID, uuid4

from app.core.status import JobStatus
from app.schemas.research import (
    AmazonCandidateResponse,
    ResearchJobResponse,
    ReviewItemResponse,
    SellerSummary,
)

# In-memory demo store (portfolio mode)
_jobs: dict[UUID, ResearchJobResponse] = {}
_items: dict[UUID, list[ReviewItemResponse]] = {}
# item_id -> "candidate:{uuid}" | "manual:{asin}" | "rejected"
_decisions: dict[UUID, str] = {}


def _now() -> datetime:
    return datetime.now(UTC)


def seed_demo_job(shopee_url: str, display_name: str | None) -> UUID:
    job_id = uuid4()
    now = _now()
    seller = SellerSummary(
        shopee_shop_url=shopee_url,
        display_name=display_name or "Demo Shopee Seller",
    )
    job = ResearchJobResponse(
        job_id=job_id,
        status=JobStatus.AWAITING_REVIEW,
        progress_pct=100,
        seller=seller,
        item_count=4,
        error=None,
        created_at=now,
        updated_at=now,
    )
    _jobs[job_id] = job

    demo_items: list[ReviewItemResponse] = []
    samples = [
        ("Wireless Bluetooth Earbuds Pro", "B0DEMO001", 0.91),
        ("USB-C Fast Charging Cable 2m", "B0DEMO002", 0.84),
        ("Portable Mini Fan Rechargeable", "B0DEMO003", 0.76),
    ]
    for title, asin, confidence in samples:
        item_id = uuid4()
        cand_id = uuid4()
        demo_items.append(
            ReviewItemResponse(
                item_id=item_id,
                title=title,
                image_url="https://picsum.photos/seed/shopee/400/400",
                sold_count=1200,
                candidates=[
                    AmazonCandidateResponse(
                        candidate_id=cand_id,
                        rank=1,
                        asin=asin,
                        amazon_url=f"https://www.amazon.com/dp/{asin}",
                        title=f"Amazon match for {title}",
                        confidence=confidence,
                    ),
                    AmazonCandidateResponse(
                        candidate_id=uuid4(),
                        rank=2,
                        asin="B0ALT001",
                        amazon_url="https://www.amazon.com/dp/B0ALT001",
                        title="Alternative match (lower confidence)",
                        confidence=round(confidence - 0.15, 2),
                    ),
                ],
                decision=None,
            )
        )
    # Item with no candidates (manual ASIN demo)
    no_match_id = uuid4()
    demo_items.append(
        ReviewItemResponse(
            item_id=no_match_id,
            title="Vintage Camera Lens Adapter Ring",
            image_url="https://picsum.photos/seed/shopee-nomatch/400/400",
            sold_count=340,
            candidates=[],
            decision=None,
        )
    )
    _items[job_id] = demo_items
    return job_id


def get_job(job_id: UUID) -> ResearchJobResponse | None:
    return _jobs.get(job_id)


def get_items(job_id: UUID, page: int, page_size: int) -> tuple[list[ReviewItemResponse], int]:
    all_items = _items.get(job_id, [])
    start = (page - 1) * page_size
    end = start + page_size
    page_items = all_items[start:end]
    # attach decisions
    enriched = []
    for item in page_items:
        decision = item.item_id if item.item_id in _decisions else None
        enriched.append(item.model_copy(update={"decision": decision}))
    return enriched, len(all_items)


def save_candidate_decision(item_id: UUID, candidate_id: UUID) -> None:
    _decisions[item_id] = f"candidate:{candidate_id}"


def save_manual_asin_decision(item_id: UUID, asin: str) -> None:
    _decisions[item_id] = f"manual:{asin.upper()}"


def save_rejected_decision(item_id: UUID) -> None:
    _decisions[item_id] = "rejected"
