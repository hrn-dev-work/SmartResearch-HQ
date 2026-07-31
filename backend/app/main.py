from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.router import api_router
from app.config import cors_origins, get_settings
from app.core.exceptions import AppError
from app.core.rate_limit import RateLimitMiddleware

settings = get_settings()

app = FastAPI(
    title="SmartResearch-HQ API",
    description="Cross-border EC research automation — portfolio mock & production pipeline",
    version="0.1.0",
)

app.add_middleware(RateLimitMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins(settings),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(AppError)
async def app_error_handler(_request: Request, exc: AppError) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": {"code": exc.code, "message": exc.message, "details": {}}},
    )


app.include_router(api_router, prefix="/api/v1")
