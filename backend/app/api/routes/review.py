from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException

from app.api.deps import ResearchService, get_research_service
from app.schemas.research import DecideReviewRequest, DecideReviewResponse
from app.services.production.research_service import ProductionResearchService

router = APIRouter(prefix="/review", tags=["review"])


@router.post("/{item_id}/decide", response_model=DecideReviewResponse)
async def decide_review(
    item_id: UUID,
    body: DecideReviewRequest,
    service: ResearchService = Depends(get_research_service),
) -> DecideReviewResponse:
    if body.rejected:
        if isinstance(service, ProductionResearchService):
            return await service.decide(item_id, None, True)
        return service.decide(item_id, None, True)

    if body.manual_asin:
        if body.candidate_id is not None:
            raise HTTPException(
                status_code=400,
                detail={"error": {"code": "VALIDATION", "message": "candidate_id and manual_asin are exclusive"}},
            )
        if isinstance(service, ProductionResearchService):
            try:
                return await service.decide(item_id, None, False, manual_asin=body.manual_asin)
            except ValueError as exc:
                if str(exc) == "INVALID_ASIN":
                    raise HTTPException(
                        status_code=400,
                        detail={"error": {"code": "INVALID_ASIN", "message": "ASIN must match BXXXXXXXXX"}},
                    ) from exc
                raise HTTPException(status_code=404, detail={"error": {"code": "NOT_FOUND", "message": str(exc)}}) from exc
        raise HTTPException(
            status_code=400,
            detail={"error": {"code": "NOT_SUPPORTED", "message": "manual_asin requires production mode"}},
        )

    if body.candidate_id is None:
        raise HTTPException(
            status_code=400,
            detail={"error": {"code": "VALIDATION", "message": "candidate_id or manual_asin required unless rejected"}},
        )

    if isinstance(service, ProductionResearchService):
        try:
            return await service.decide(item_id, body.candidate_id, False)
        except ValueError as exc:
            raise HTTPException(status_code=400, detail={"error": {"code": "VALIDATION", "message": str(exc)}}) from exc
    return service.decide(item_id, body.candidate_id, False)
