from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query

from app.api.deps import ResearchService, get_research_service
from app.schemas.research import (
    CreateResearchRequest,
    CreateResearchResponse,
    ExportJobResponse,
    ResearchJobResponse,
    ReviewItemsPageResponse,
)
from app.services.production.research_service import ProductionResearchService
from app.workers.queue import enqueue_research_job

router = APIRouter(prefix="/research", tags=["research"])


@router.post("", response_model=CreateResearchResponse, status_code=201)
async def create_research(
    body: CreateResearchRequest,
    service: ResearchService = Depends(get_research_service),
) -> CreateResearchResponse:
    url = str(body.shopee_shop_url)
    name = body.seller_display_name
    if isinstance(service, ProductionResearchService):
        result = await service.create_research(url, name)
        await enqueue_research_job(result.job_id)
        return result
    return service.create_research(url, name)


@router.get("/{job_id}", response_model=ResearchJobResponse)
async def get_research_job(
    job_id: UUID,
    service: ResearchService = Depends(get_research_service),
) -> ResearchJobResponse:
    if isinstance(service, ProductionResearchService):
        job = await service.get_job(job_id)
    else:
        job = service.get_job(job_id)
    if job is None:
        raise HTTPException(
            status_code=404, detail={"error": {"code": "NOT_FOUND", "message": str(job_id)}}
        )
    return job


@router.get("/{job_id}/items", response_model=ReviewItemsPageResponse)
async def list_research_items(
    job_id: UUID,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    service: ResearchService = Depends(get_research_service),
) -> ReviewItemsPageResponse:
    if isinstance(service, ProductionResearchService):
        result = await service.list_items(job_id, page, page_size)
    else:
        result = service.list_items(job_id, page, page_size)
    if result is None:
        raise HTTPException(
            status_code=404, detail={"error": {"code": "NOT_FOUND", "message": str(job_id)}}
        )
    return result


@router.post("/{job_id}/export", response_model=ExportJobResponse, status_code=202)
async def export_research_job(
    job_id: UUID,
    service: ResearchService = Depends(get_research_service),
) -> ExportJobResponse:
    if isinstance(service, ProductionResearchService):
        try:
            result = await service.export_job(job_id)
        except ValueError as exc:
            raise HTTPException(
                status_code=400,
                detail={"error": {"code": "SPREADSHEET_CONFIG", "message": str(exc)}},
            ) from exc
    else:
        result = service.export_job(job_id)
    if result is None:
        raise HTTPException(
            status_code=404, detail={"error": {"code": "NOT_FOUND", "message": str(job_id)}}
        )
    return result
