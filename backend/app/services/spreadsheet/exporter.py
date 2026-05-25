"""Google Sheets export (production — Phase 2, WBS 2.3)."""

from __future__ import annotations

import asyncio
from datetime import datetime
from pathlib import Path
from typing import Any

from google.oauth2 import service_account
from googleapiclient.discovery import build

SCOPES = ["https://www.googleapis.com/auth/spreadsheets"]

SHEET_HEADER = [
    "Shopee Title",
    "Shopee Item ID",
    "Amazon ASIN",
    "Amazon URL",
    "Sold Count",
    "Exported At (UTC)",
]


class SpreadsheetConfigError(Exception):
    """Google Sheets credentials or sheet ID are missing or invalid."""


def build_export_row(
    *,
    shopee_title: str,
    shopee_item_id: str,
    amazon_asin: str,
    amazon_url: str,
    sold_count: int | None,
    exported_at: datetime,
) -> dict[str, Any]:
    return {
        "shopee_title": shopee_title,
        "shopee_item_id": shopee_item_id,
        "amazon_asin": amazon_asin,
        "amazon_url": amazon_url,
        "sold_count": sold_count if sold_count is not None else "",
        "exported_at": exported_at.replace(microsecond=0).isoformat(),
    }


def _row_to_values(row: dict[str, Any]) -> list[Any]:
    return [
        row["shopee_title"],
        row["shopee_item_id"],
        row["amazon_asin"],
        row["amazon_url"],
        row["sold_count"],
        row["exported_at"],
    ]


def _validate_config(sheet_id: str, credentials_path: str) -> None:
    if not sheet_id.strip():
        raise SpreadsheetConfigError("GOOGLE_SHEET_ID is not set")
    path = Path(credentials_path)
    if not path.is_file():
        raise SpreadsheetConfigError(f"Credentials file not found: {credentials_path}")


def _append_rows_sync(
    sheet_id: str,
    rows: list[dict[str, Any]],
    *,
    credentials_path: str,
    include_header: bool = False,
) -> int:
    _validate_config(sheet_id, credentials_path)
    values = [_row_to_values(row) for row in rows]
    if include_header:
        values = [SHEET_HEADER, *values]

    creds = service_account.Credentials.from_service_account_file(credentials_path, scopes=SCOPES)
    service = build("sheets", "v4", credentials=creds, cache_discovery=False)
    service.spreadsheets().values().append(
        spreadsheetId=sheet_id,
        range="A1",
        valueInputOption="USER_ENTERED",
        insertDataOption="INSERT_ROWS",
        body={"values": values},
    ).execute()
    return len(rows)


async def export_rows(
    sheet_id: str,
    rows: list[dict[str, Any]],
    *,
    credentials_path: str,
    include_header: bool = False,
) -> int:
    """Append approved research rows to the configured spreadsheet."""
    if not rows:
        return 0
    return await asyncio.to_thread(
        _append_rows_sync,
        sheet_id,
        rows,
        credentials_path=credentials_path,
        include_header=include_header,
    )
