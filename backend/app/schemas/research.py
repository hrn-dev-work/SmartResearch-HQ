from datetime import datetime
from uuid import UUID

from app.core.status import JobStatus
from pydantic import BaseModel, Field, HttpUrl


class CreateResearchRequest(BaseModel):
    shopee_shop_url: HttpUrl
    seller_display_name: str | None = None


class CreateResearchResponse(BaseModel):
    job_id: UUID
    status: JobStatus
    progress_pct: int = Field(ge=0, le=100)


class SellerSummary(BaseModel):
    shopee_shop_url: str
    display_name: str | None


class JobError(BaseModel):
    code: str
    message: str


class ResearchJobResponse(BaseModel):
    job_id: UUID
    status: JobStatus
    progress_pct: int
    seller: SellerSummary
    item_count: int
    error: JobError | None
    created_at: datetime
    updated_at: datetime


class AmazonCandidateResponse(BaseModel):
    candidate_id: UUID
    rank: int
    asin: str
    amazon_url: str
    title: str
    confidence: float


class ReviewItemResponse(BaseModel):
    item_id: UUID
    title: str
    image_url: str
    sold_count: int | None
    candidates: list[AmazonCandidateResponse]
    decision: UUID | None


class ReviewItemsPageResponse(BaseModel):
    items: list[ReviewItemResponse]
    page: int
    page_size: int
    total: int


class DecideReviewRequest(BaseModel):
    candidate_id: UUID | None = None
    manual_asin: str | None = None
    rejected: bool = False


class DecideReviewResponse(BaseModel):
    item_id: UUID
    status: str
    exported: bool


class ExportJobResponse(BaseModel):
    job_id: UUID
    exported_count: int
    skipped_count: int
