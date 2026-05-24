from fastapi import APIRouter

from app.api.routes import health, research, review

api_router = APIRouter()
api_router.include_router(health.router)
api_router.include_router(research.router)
api_router.include_router(review.router)
