#!/usr/bin/env bash
# Docs-only PR path: verify (no npm/pytest) → push → ensure-pr once.
# Usage: bash scripts/git-pr-docs-only.sh
# Log: .git-pr-docs-only.log

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
# shellcheck source=gh-pr-branch.sh
source "$ROOT/scripts/gh-pr-branch.sh"

LOG="$ROOT/.git-pr-docs-only.log"
: >"$LOG"
exec > >(tee -a "$LOG") 2>&1

BRANCH="$(git branch --show-current)"
BASE="${GIT_PR_BASE:-main}"

if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
  echo "ERROR: run from a feature branch, not ${BRANCH}." >&2
  exit 1
fi

echo "== git-pr-docs-only $(date -Iseconds) branch=${BRANCH} =="
git fetch origin

echo "== docs verify (skip frontend/backend ci-check) =="
bash scripts/check-bash-script-cycles.sh
bash scripts/verify-wsl-workspace.sh
bash scripts/check-pr-tooling.sh
bash scripts/validate-public-docs.sh

echo "== push =="
git push -u origin HEAD

PR_NUM="$(gh_pr_number_for_branch "$BRANCH")"
PR_URL="$(gh_pr_url_for_branch "$BRANCH")"

if [[ -n "$PR_NUM" && "$PR_NUM" =~ ^[0-9]+$ ]]; then
  echo "Open PR already exists: #${PR_NUM} ${PR_URL}"
  bash scripts/sync-pr-body.sh "$BRANCH" "$BASE" || true
else
  echo "Creating PR (single attempt; retry manually if rate limited)..."
  bash scripts/ensure-pr.sh "$BASE"
  PR_URL="$(gh_pr_url_for_branch "$BRANCH")"
fi

echo "PR_URL=${PR_URL:-unknown}"
git log -1 --oneline
git status -sb
