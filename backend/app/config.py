from enum import Enum
from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class AppMode(str, Enum):
    PORTFOLIO = "portfolio"
    PRODUCTION = "production"


class MatchingProvider(str, Enum):
    AMAZON_SEARCH = "amazon_search"
    NONE = "none"
    GEMINI = "gemini"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_mode: AppMode = AppMode.PORTFOLIO
    matching_provider: MatchingProvider = MatchingProvider.AMAZON_SEARCH
    backend_host: str = "0.0.0.0"
    backend_port: int = 8000
    database_url: str = (
        "postgresql+asyncpg://smartresearch:smartresearch@localhost:5432/smartresearch"
    )
    redis_url: str = "redis://localhost:6379/0"
    gemini_api_key: str = ""
    gemini_model: str = "gemini-2.0-flash"
    amazon_paapi_access_key: str = ""
    amazon_paapi_secret_key: str = ""
    amazon_paapi_partner_tag: str = ""
    amazon_paapi_region: str = "us-east-1"
    google_sheets_credentials_path: str = "./credentials.json"
    google_sheet_id: str = ""
    max_scrape_items: int = 20


@lru_cache
def get_settings() -> Settings:
    return Settings()
