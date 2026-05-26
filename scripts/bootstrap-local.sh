#!/usr/bin/env bash
# Run inside WSL Ubuntu: bash scripts/bootstrap-local.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> SmartResearch-HQ local bootstrap (WSL/Linux bash)"

test -f .env || cp .env.example .env
test -f frontend/.env.local || cp frontend/.env.local.example frontend/.env.local

echo "==> Backend: venv + dependencies"
if ! python3 -m venv --help >/dev/null 2>&1; then
  echo "ERROR: python3-venv is not installed."
  echo "  Run: sudo apt install python3.12-venv"
  exit 1
fi
cd "$ROOT/backend"
rm -rf .venv
python3 -m venv .venv
if [[ ! -f .venv/bin/activate ]]; then
  echo "ERROR: venv creation failed (often missing python3.12-venv)."
  echo "  Run: sudo apt install python3.12-venv"
  exit 1
fi
# shellcheck source=/dev/null
source .venv/bin/activate
python -m pip install --upgrade pip -q
pip install -r requirements.txt -q
echo "    python: $(which python)"
echo "    uvicorn: $(which uvicorn)"

echo "==> Playwright Chromium (Phase 2 scrape)"
playwright install chromium
echo "    If scrape fails with libnspr4.so missing, run once (password required):"
echo "    sudo $ROOT/backend/.venv/bin/playwright install-deps chromium"

echo "==> Frontend: npm dependencies"
cd "$ROOT/frontend"
if command -v npm >/dev/null 2>&1; then
  npm install --silent
  echo "    npm: $(which npm)"
else
  echo "    WARN: npm not found — install Node.js in WSL (e.g. nvm or apt)"
fi

echo ""
echo "Done. Start servers in two WSL terminals:"
echo "  1) cd $ROOT/backend && source .venv/bin/activate && uvicorn app.main:app --reload --port 8000"
echo "  2) cd $ROOT/frontend && npm run dev"
echo ""
echo "Or run: bash scripts/start-dev.sh"
echo ""
echo "Optional — auto PR after git push:"
echo "  bash scripts/install-git-hooks.sh"
echo "  # PR: bash scripts/git-ship.sh pr  (after push)"
