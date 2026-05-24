"""
Google Sheets exporter (production — Phase 2).
"""


async def export_rows(sheet_id: str, rows: list[dict], *, credentials_path: str) -> int:
    """Append approved ASIN rows to the configured spreadsheet."""
    raise NotImplementedError("Google Sheets export — implement in Phase 2 (production mode)")
