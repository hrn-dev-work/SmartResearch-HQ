#!/usr/bin/env bash
# Regenerate PR body from render-pr-body.sh (Commits + CI checkboxes).
# Usage: bash scripts/sync-pr-body.sh [branch] [base]

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
# shellcheck source=gh-pr-branch.sh
source "$ROOT/scripts/gh-pr-branch.sh"

BRANCH="${1:-$(git branch --show-current)}"
BASE="${2:-main}"
PR_NUM="$(gh_pr_number_for_branch "$BRANCH")"

if [[ -z "$PR_NUM" ]]; then
  echo "No open PR for branch: ${BRANCH}" >&2
  exit 1
fi

BODY="$(bash "$ROOT/scripts/render-pr-body.sh" auto "$BRANCH" "$BASE")"
gh pr edit "$PR_NUM" --body "$BODY"
bash "$ROOT/scripts/sync-pr-checkboxes.sh" "$PR_NUM" || true
echo "PR #${PR_NUM} body synced"
