"""CLI entry point for local production pipeline testing (Phase 2)."""

from __future__ import annotations

import argparse
import asyncio
import sys
from uuid import UUID

from app.config import AppMode, get_settings
from app.db.session import SessionLocal
from app.services.production.pipeline import create_job_record, run_job_pipeline
from app.services.production.research_service import ProductionResearchService
from app.services.scraper.shopee_crawler import fetch_sold_items


async def cmd_scrape(args: argparse.Namespace) -> int:
    items = await fetch_sold_items(args.url, headless=not args.headful, max_items=args.limit)
    print(f"Extracted {len(items)} item(s):")
    for item in items:
        sold = item.sold_count if item.sold_count is not None else "?"
        print(f"  - [{item.shopee_item_id}] {item.title} (sold={sold})")
    return 0


async def cmd_run(args: argparse.Namespace) -> int:
    settings = get_settings()
    if settings.app_mode != AppMode.PRODUCTION:
        print("WARN: APP_MODE is not production — pipeline still runs against real DB/scraper")

    async with SessionLocal() as session:
        job = await create_job_record(
            session,
            shopee_shop_url=args.url,
            seller_display_name=args.name,
        )
        await session.commit()
        job_id = job.id
        print(f"Created job {job_id}")

        service = ProductionResearchService(session)
        await service.run_pipeline(job_id, max_items=args.limit)

        refreshed = await service.get_job(job_id)
        if refreshed is None:
            print("Job missing after pipeline")
            return 1
        print(
            f"Status: {refreshed.status.value}  items={refreshed.item_count}  progress={refreshed.progress_pct}%"
        )
        if refreshed.error:
            print(f"Error: {refreshed.error.code} — {refreshed.error.message}")
            return 1

        page = await service.list_items(job_id, page=1, page_size=5)
        if page:
            for item in page.items:
                print(f"  • {item.title[:60]} — {len(item.candidates)} candidate(s)")
        return 0


async def cmd_migrate(_args: argparse.Namespace) -> int:
    from alembic.config import Config
    from alembic import command

    alembic_cfg = Config("alembic.ini")
    command.upgrade(alembic_cfg, "head")
    print("Alembic upgrade head — done")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="python -m app.cli")
    sub = parser.add_subparsers(dest="command", required=True)

    scrape = sub.add_parser("scrape", help="Test Playwright scraper only")
    scrape.add_argument("--url", required=True, help="Shopee shop URL")
    scrape.add_argument("--limit", type=int, default=10)
    scrape.add_argument("--headful", action="store_true", help="Show browser window")
    scrape.set_defaults(func=cmd_scrape)

    run = sub.add_parser("run", help="Create job + run full pipeline (M2)")
    run.add_argument("--url", required=True, help="Shopee shop URL")
    run.add_argument("--name", default=None, help="Seller display name")
    run.add_argument("--limit", type=int, default=10)
    run.set_defaults(func=cmd_run)

    migrate = sub.add_parser("migrate", help="Run alembic upgrade head")
    migrate.set_defaults(func=cmd_migrate)

    return parser


async def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return await args.func(args)


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
