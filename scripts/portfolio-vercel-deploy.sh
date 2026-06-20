#!/usr/bin/env bash
# Portfolio frontend — Vercel production deploy (CLI).
#
# Usage:
#   bash scripts/portfolio-vercel-deploy.sh          # sync main + build + deploy
#   bash scripts/portfolio-vercel-deploy.sh redeploy # frontend only (after first setup)
#
# Prerequisites: npx vercel login (once). Render API must be live.
# Logs: .agent-local/portfolio-vercel-deploy.log (gitignored)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=agent-local-log.sh
source "$(dirname "$0")/agent-local-log.sh"
LOG="$(agent_local_log_path portfolio-vercel-deploy.log)"
API_URL="${NEXT_PUBLIC_API_URL:-https://smartresearch-api.onrender.com/api/v1}"
VERCEL_PROJECT="${VERCEL_PROJECT:-smart-research-hq}"
PRODUCTION_URL="${PORTFOLIO_PRODUCTION_URL:-https://smart-research-hq.vercel.app}"
MODE="${1:-full}"

: >"$LOG"
exec > >(tee -a "$LOG") 2>&1

echo "== portfolio vercel deploy mode=$MODE $(date -Iseconds) =="

sync_main() {
  cd "$ROOT"
  git fetch origin
  git checkout main
  if [[ -f scripts/dev.sh ]] && ! git cat-file -e "origin/main:scripts/dev.sh" 2>/dev/null; then
    echo "Removing local scripts/dev.sh (deleted on origin/main)"
    rm -f scripts/dev.sh
  fi
  git stash push -u -m "portfolio-vercel-deploy-$(date +%s)" || true
  git pull --ff-only origin main
  echo "On $(git rev-parse --short HEAD) ($(git branch --show-current))"
}

if [[ "$MODE" == "full" ]]; then
  sync_main
elif [[ "$MODE" != "redeploy" ]]; then
  echo "Usage: bash scripts/portfolio-vercel-deploy.sh [full|redeploy]" >&2
  exit 2
fi

cd "$ROOT/frontend"
npm ci
NEXT_PUBLIC_API_URL="$API_URL" npm run build

if [[ ! -f .vercel/project.json ]]; then
  echo "Linking frontend to Vercel project ${VERCEL_PROJECT}"
  npx vercel link --yes --project "$VERCEL_PROJECT"
fi

ensure_env() {
  local target="$1"
  if npx vercel env ls "$target" 2>/dev/null | grep -q "NEXT_PUBLIC_API_URL"; then
    echo "NEXT_PUBLIC_API_URL already set for ${target}"
    return 0
  fi
  printf '%s\n' "$API_URL" | npx vercel env add NEXT_PUBLIC_API_URL "$target"
}

ensure_env production
ensure_env preview
ensure_env development

echo "NEXT_PUBLIC_API_URL=$API_URL" > .env.local

NEXT_PUBLIC_API_URL="$API_URL" npx vercel --prod --yes

echo "== smoke $PRODUCTION_URL =="
curl -sS -I "$PRODUCTION_URL" | head -15 || true

echo "== done. If 404 in normal browser, try incognito (cached 404) or turn off Vercel Authentication. =="
echo "See docs/deployment-troubleshooting.md"
