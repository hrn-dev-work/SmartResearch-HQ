from datetime import UTC, datetime
from uuid import UUID, uuid4

from app.core.status import JobStatus
from app.schemas.research import (
    AmazonCandidateResponse,
    ResearchJobResponse,
    ReviewItemResponse,
    SellerSummary,
)
from app.services.scraper.shopee_crawler import build_shopee_item_url

# In-memory demo store (portfolio mode)
_jobs: dict[UUID, ResearchJobResponse] = {}
_items: dict[UUID, list[ReviewItemResponse]] = {}
# item_id -> API decision marker (candidate_id or synthetic decision UUID)
_decision_markers: dict[UUID, UUID] = {}
_rejected_items: set[UUID] = set()
_manual_asins: dict[UUID, str] = {}
_exported_at: dict[UUID, datetime] = {}


def _now() -> datetime:
    return datetime.now(UTC)


def _demo_item_url(shop_url: str, item_id: str) -> str:
    return build_shopee_item_url(shop_url, item_id, shop_id="123456")


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
        ("10001", "Wireless Bluetooth Earbuds Pro", "B0DEMO001", 0.91),
        ("10002", "USB-C Fast Charging Cable 2m", "B0DEMO002", 0.84),
        ("10003", "Portable Mini Fan Rechargeable", "B0DEMO003", 0.76),
    ]
    for shopee_item_id, title, asin, confidence in samples:
        item_id = uuid4()
        cand_id = uuid4()
        demo_items.append(
            ReviewItemResponse(
                item_id=item_id,
                shopee_item_id=shopee_item_id,
                title=title,
                image_url="https://picsum.photos/seed/shopee/400/400",
                shopee_item_url=_demo_item_url(shopee_url, shopee_item_id),
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
    no_match_id = uuid4()
    demo_items.append(
        ReviewItemResponse(
            item_id=no_match_id,
            shopee_item_id="10004",
            title="Vintage Camera Lens Adapter Ring",
            image_url="https://picsum.photos/seed/shopee-nomatch/400/400",
            shopee_item_url=_demo_item_url(shopee_url, "10004"),
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
    enriched = []
    for item in page_items:
        marker = _decision_markers.get(item.item_id)
        enriched.append(item.model_copy(update={"decision": marker}))
    return enriched, len(all_items)


def save_candidate_decision(item_id: UUID, candidate_id: UUID) -> None:
    _decision_markers[item_id] = candidate_id
    _rejected_items.discard(item_id)


def save_manual_asin_decision(item_id: UUID, asin: str) -> None:
    _decision_markers[item_id] = uuid4()
    _manual_asins[item_id] = asin.upper()
    _rejected_items.discard(item_id)


def save_rejected_decision(item_id: UUID) -> None:
    _decision_markers[item_id] = uuid4()
    _rejected_items.add(item_id)


def mark_exported(item_ids: list[UUID], exported_at: datetime) -> None:
    for item_id in item_ids:
        _exported_at[item_id] = exported_at


def set_job_status(job_id: UUID, status: JobStatus) -> None:
    job = _jobs.get(job_id)
    if job is None:
        return
    _jobs[job_id] = job.model_copy(update={"status": status, "updated_at": _now()})


def is_rejected(item_id: UUID) -> bool:
    return item_id in _rejected_items


def is_exported(item_id: UUID) -> bool:
    return item_id in _exported_at


def manual_asin_for(item_id: UUID) -> str | None:
    return _manual_asins.get(item_id)
