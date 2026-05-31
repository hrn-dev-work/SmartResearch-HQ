#!/usr/bin/env bash
# M2 smoke: CLI scrape + full pipeline (production mode).
# Requires: docker compose (postgres/redis), Playwright, PA-API keys in .env
#
# Usage:
#   bash scripts/smoke-m2.sh
#   SHOPEE_URL="https://shopee.sg/..." bash scripts/smoke-m2.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SHOPEE_URL="${SHOPEE_URL:-https://shopee.sg/demo-shop}"
ITEM_LIMIT="${ITEM_LIMIT:-5}"

echo "== M2 smoke (Phase 2) =="
echo "Shop URL: $SHOPEE_URL (limit=$ITEM_LIMIT)"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found — start postgres/redis manually" >&2
else
  docker compose up -d postgres redis
fi

cd backend
if [[ ! -d .venv ]]; then
  python3 -m venv .venv
fi
# shellcheck disable=SC1091
source .venv/bin/activate
pip install -q -r requirements-dev.txt
playwright install chromium

python -m app.cli migrate

echo ""
echo "== scrape only =="
python -m app.cli scrape --url "$SHOPEE_URL" --limit "$ITEM_LIMIT"

echo ""
echo "== full pipeline (requires APP_MODE=production + PA-API in .env) =="
if [[ "${SKIP_PIPELINE:-0}" == "1" ]]; then
  echo "SKIP_PIPELINE=1 — skipping run"
  exit 0
fi

python -m app.cli run --url "$SHOPEE_URL" --limit "$ITEM_LIMIT" --name "M2 smoke"

echo ""
echo "M2 smoke finished. For API path, start worker in another terminal:"
echo "  arq app.workers.settings.WorkerSettings"
