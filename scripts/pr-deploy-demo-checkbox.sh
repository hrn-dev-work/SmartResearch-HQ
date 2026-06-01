#!/usr/bin/env bash
# Demo URL test-plan checkbox: "N/A" (no deploy diff) or " " (unchecked — deploy touched).
# Usage: bash scripts/pr-deploy-demo-checkbox.sh [branch|pr-number] [base]
#
# Exit 0; prints exactly one token: N/A or a single space.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
# shellcheck source=gh-pr-branch.sh
source "$ROOT/scripts/gh-pr-branch.sh"

TARGET="${1:-$(git branch --show-current)}"
BASE="${2:-main}"
REPO="${GITHUB_REPOSITORY:-hrn-dev-work/SmartResearch-HQ}"

export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"

is_deploy_path() {
  local f="$1"
  case "$f" in
    docs/deployment-*)
      return 0
      ;;
    scripts/portfolio-vercel-deploy.sh | scripts/agent-push.sh)
      return 0
      ;;
    render.yaml | render.yml | vercel.json | docker-compose.yml)
      return 0
      ;;
    frontend/next.config.* | frontend/.env* | frontend/.env.*)
      return 0
      ;;
    .github/workflows/*deploy* | .github/workflows/*vercel*)
      return 0
      ;;
  esac
  return 1
}

collect_changed_files() {
  local target="$1"
  if [[ "$target" =~ ^[0-9]+$ ]]; then
    gh pr view "$target" --repo "$REPO" --json files -q '.files[].path' 2>/dev/null || true
    return
  fi

  git fetch origin "$BASE" 2>/dev/null || true
  if git rev-parse "origin/${BASE}" >/dev/null 2>&1; then
    git diff --name-only "origin/${BASE}...HEAD" 2>/dev/null || true
  else
    git diff --name-only "${BASE}...HEAD" 2>/dev/null || true
  fi
}

touches_deploy=0
while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  if is_deploy_path "$path"; then
    touches_deploy=1
    break
  fi
done < <(collect_changed_files "$TARGET")

if [[ "$touches_deploy" -eq 0 ]]; then
  echo "N/A"
else
  printf ' '
fi
