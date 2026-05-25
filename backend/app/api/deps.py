from typing import Annotated

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import AppMode, get_settings
from app.db.session import get_db_session_optional
from app.services.matching import get_candidate_matcher
from app.services.matching.protocol import CandidateMatcher
from app.services.mock.research_service import MockResearchService
from app.services.production.research_service import ProductionResearchService

ResearchService = MockResearchService | ProductionResearchService


async def get_research_service(
    session: Annotated[AsyncSession | None, Depends(get_db_session_optional)],
) -> ResearchService:
    settings = get_settings()
    if settings.app_mode == AppMode.PRODUCTION:
        if session is None:
            raise RuntimeError("DB session required in production mode")
        return ProductionResearchService(session)
    return MockResearchService()


def get_matcher() -> CandidateMatcher:
    return get_candidate_matcher()
