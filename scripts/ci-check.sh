#!/usr/bin/env bash
# Local CI mirror (.github/workflows/ci.yml). Usage: bash scripts/ci-check.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

bash "$ROOT/scripts/sync-wbs-roadmap.sh" --quiet || true

echo "== secret audit =="
bash "$ROOT/scripts/secret-audit.sh"

echo "== backend =="
cd "$ROOT/backend"
if [[ ! -d .venv ]]; then
  python3 -m venv .venv
fi
# shellcheck disable=SC1091
source .venv/bin/activate
python "$ROOT/scripts/sync-api-types.py" --quiet || true
python -m pip install -q -r requirements-dev.txt
ruff check .
ruff format --check .
APP_MODE=portfolio MATCHING_PROVIDER=amazon_search pytest -q

ensure_npm() {
  if command -v npm >/dev/null 2>&1; then
    return 0
  fi
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    # shellcheck disable=SC1091
    source "$NVM_DIR/nvm.sh"
  fi
  if ! command -v npm >/dev/null 2>&1; then
    echo "npm not found. Install Node (e.g. nvm install 20) or add npm to PATH." >&2
    exit 1
  fi
}

echo "== frontend =="
cd "$ROOT/frontend"
ensure_npm
npm ci
python3 "$ROOT/scripts/sync-api-types.py" --check
npm run lint
NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1 npm run build

echo "CI checks passed."
