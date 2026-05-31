#!/usr/bin/env bash
# Bootstrap local production stack (裏版). Does NOT deploy to public URLs.
# Usage: bash scripts/start-production-local.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "== SmartResearch-HQ production local bootstrap =="
echo "This prepares DB/Redis/migrations. Set APP_MODE=production in .env before API/worker."

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created .env from .env.example"
fi

if grep -q '^APP_MODE=portfolio' .env 2>/dev/null; then
  echo ""
  echo "NOTE: APP_MODE is still 'portfolio' in .env."
  echo "      Change to APP_MODE=production when running API/worker/CLI pipeline."
  echo ""
fi

if command -v docker >/dev/null 2>&1; then
  echo "== Docker: postgres + redis =="
  docker compose up -d postgres redis
  echo "Waiting for healthchecks..."
  sleep 3
  docker compose ps postgres redis
else
  echo "WARN: docker not found — start postgres/redis manually" >&2
fi

echo "== Backend venv + deps =="
cd "$ROOT/backend"
if [[ ! -d .venv ]]; then
  python3 -m venv .venv
fi
# shellcheck disable=SC1091
source .venv/bin/activate
python -m pip install -q -U pip
pip install -q -r requirements-dev.txt

if ! playwright install chromium >/dev/null 2>&1; then
  echo "WARN: playwright install chromium failed — run manually if scrape fails" >&2
fi

echo "== Alembic migrate =="
python -m app.cli migrate

echo ""
echo "== Environment checklist (.env) =="
check_var() {
  local key="$1"
  local label="$2"
  if grep -q "^${key}=" "$ROOT/.env" 2>/dev/null; then
    local val
    val="$(grep "^${key}=" "$ROOT/.env" | head -1 | cut -d= -f2-)"
    if [[ -n "$val" ]]; then
      echo "  [ok] $label"
    else
      echo "  [ ] $label (empty)"
    fi
  else
    echo "  [ ] $label (missing)"
  fi
}

check_var APP_MODE "APP_MODE=production"
check_var DATABASE_URL "DATABASE_URL"
check_var REDIS_URL "REDIS_URL"
check_var AMAZON_PAAPI_ACCESS_KEY "AMAZON_PAAPI_ACCESS_KEY (amazon_search)"
check_var AMAZON_PAAPI_SECRET_KEY "AMAZON_PAAPI_SECRET_KEY"
check_var AMAZON_PAAPI_PARTNER_TAG "AMAZON_PAAPI_PARTNER_TAG"
check_var GEMINI_API_KEY "GEMINI_API_KEY (optional, gemini only)"
check_var GOOGLE_SHEET_ID "GOOGLE_SHEET_ID (optional, Sheets export)"

echo ""
echo "== Next steps =="
echo "  1. Edit .env: APP_MODE=production, PA-API keys if using amazon_search"
echo "  2. Scrape only:  SKIP_PIPELINE=1 bash scripts/smoke-m2.sh"
echo "  3. Full pipeline: bash scripts/smoke-m2.sh  (needs PA-API)"
echo "  4. API:    cd backend && APP_MODE=production uvicorn app.main:app --reload --port 8000"
echo "  5. Worker: cd backend && arq app.workers.settings.WorkerSettings"
echo "  6. UI:     cd frontend && NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1 npm run dev"
echo ""
echo "Docs: docs/production-local-setup.md (public)"
echo "      docs/local/production-overview.md (local, gitignored)"
