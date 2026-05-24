from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.config import AppMode, get_settings

_settings = get_settings()
engine = create_async_engine(_settings.database_url, echo=False)
SessionLocal = async_sessionmaker(engine, expire_on_commit=False)


async def get_db_session() -> AsyncGenerator[AsyncSession, None]:
    async with SessionLocal() as session:
        yield session


async def get_db_session_optional() -> AsyncGenerator[AsyncSession | None, None]:
    if get_settings().app_mode == AppMode.PORTFOLIO:
        yield None
        return
    async with SessionLocal() as session:
        yield session
