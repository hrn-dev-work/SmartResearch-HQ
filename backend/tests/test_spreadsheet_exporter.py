from datetime import UTC, datetime

from app.services.spreadsheet.exporter import (
    SHEET_HEADER,
    SpreadsheetConfigError,
    _append_rows_sync,
    build_export_row,
)


def test_build_export_row():
    exported_at = datetime(2026, 5, 25, 12, 0, tzinfo=UTC)
    row = build_export_row(
        shopee_title="Sample Item",
        shopee_item_id="12345",
        amazon_asin="B012345678",
        amazon_url="https://www.amazon.com/dp/B012345678",
        sold_count=42,
        exported_at=exported_at,
    )
    assert row["amazon_asin"] == "B012345678"
    assert row["sold_count"] == 42
    assert row["exported_at"] == "2026-05-25T12:00:00+00:00"


def test_append_rows_sync_validates_sheet_id(tmp_path):
    creds = tmp_path / "creds.json"
    creds.write_text("{}", encoding="utf-8")
    try:
        _append_rows_sync("", [], credentials_path=str(creds))
        assert False, "expected SpreadsheetConfigError"
    except SpreadsheetConfigError as exc:
        assert "GOOGLE_SHEET_ID" in str(exc)


def test_sheet_header_columns():
    assert "Amazon ASIN" in SHEET_HEADER
    assert len(SHEET_HEADER) == 6
