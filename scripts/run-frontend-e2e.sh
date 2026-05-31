#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
API_URL="${NEXT_PUBLIC_API_URL:-http://127.0.0.1:8000/api/v1}"
BASE_URL="${PLAYWRIGHT_BASE_URL:-http://127.0.0.1:3000}"
BACKEND_PID=""
API_LOG="${TMPDIR:-/tmp}/srh-e2e-api.log"
cleanup() {
  if [[ -n "$BACKEND_PID" ]] && kill -0 "$BACKEND_PID" 2>/dev/null; then
    kill "$BACKEND_PID" 2>/dev/null || true
    wait "$BACKEND_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT
cd "$ROOT/backend"
if [[ ! -d .venv ]]; then python3 -m venv .venv; fi
source .venv/bin/activate
python -m pip install -q -r requirements-dev.txt
APP_MODE=portfolio MATCHING_PROVIDER=amazon_search \
  uvicorn app.main:app --host 127.0.0.1 --port 8000 >"$API_LOG" 2>&1 &
BACKEND_PID=$!
for i in $(seq 1 45); do
  if curl -sf "${API_URL}/health" | grep -q '"mode":"portfolio"'; then break; fi
  if [[ "$i" -eq 45 ]]; then echo "backend health timeout" >&2; exit 1; fi
  sleep 1
done
cd "$ROOT/frontend"
if [[ "${CI:-}" == "true" ]]; then npx playwright install --with-deps chromium
else npx playwright install chromium; fi
if [[ "${SKIP_FRONTEND_BUILD:-}" != "1" ]]; then
  NEXT_PUBLIC_API_URL="$API_URL" npm run build
fi
export CI=true NEXT_PUBLIC_API_URL="$API_URL" PLAYWRIGHT_BASE_URL="$BASE_URL"
npm run e2e
