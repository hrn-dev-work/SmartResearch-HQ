#!/usr/bin/env bash
# Run inside WSL Ubuntu: bash scripts/start-dev.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ ! -f "$ROOT/backend/.venv/bin/activate" ]]; then
  echo "Missing venv. Run first: bash scripts/bootstrap-local.sh"
  exit 1
fi

# shellcheck source=/dev/null
source "$ROOT/backend/.venv/bin/activate"

echo "Starting backend on :8000 ..."
cd "$ROOT/backend"
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 &
BACKEND_PID=$!

cleanup() {
  kill "$BACKEND_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

sleep 2
if curl -sf http://127.0.0.1:8000/api/v1/health >/dev/null; then
  echo "Backend OK: $(curl -s http://127.0.0.1:8000/api/v1/health)"
else
  echo "Backend failed to start. Check logs above."
  exit 1
fi

echo "Starting frontend on :3000 ..."
cd "$ROOT/frontend"
exec npm run dev
