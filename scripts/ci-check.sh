#!/usr/bin/env bash
# Local CI mirror (.github/workflows/ci.yml). Usage: bash scripts/ci-check.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "== backend =="
cd "$ROOT/backend"
if [[ ! -d .venv ]]; then
  python3 -m venv .venv
fi
# shellcheck disable=SC1091
source .venv/bin/activate
python -m pip install -q -r requirements-dev.txt
ruff check .
ruff format --check .
APP_MODE=portfolio MATCHING_PROVIDER=amazon_search pytest -q

echo "== frontend =="
cd "$ROOT/frontend"
npm ci
npm run lint
NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1 npm run build

echo "CI checks passed."
