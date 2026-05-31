#!/usr/bin/env bash
# Regenerate PR body from commits (render-pr-body.sh auto) and apply CI checkbox marks.
# Usage: bash scripts/sync-pr-body.sh [branch|pr-number] [base]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
# shellcheck source=gh-pr-branch.sh
source "$ROOT/scripts/gh-pr-branch.sh"

export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
REPO="${GITHUB_REPOSITORY:-hrn-dev-work/SmartResearch-HQ}"
TARGET="${1:-$(git branch --show-current)}"
BASE="${2:-main}"
PR_NUM=""

if [[ "$TARGET" =~ ^[0-9]+$ ]]; then
  PR_NUM="$TARGET"
else
  PR_NUM="$(gh_pr_number_for_branch "$TARGET" "$REPO")"
fi

if [[ -z "$PR_NUM" ]]; then
  echo "No open PR for: ${TARGET} (skip body sync)" >&2
  exit 0
fi

BRANCH="$(gh pr view "$PR_NUM" --repo "$REPO" --json headRefName -q .headRefName)"
BODY_FILE="$(mktemp)"
trap 'rm -f "$BODY_FILE"' EXIT

bash "$ROOT/scripts/render-pr-body.sh" auto "$BRANCH" "$BASE" >"$BODY_FILE"
gh pr edit "$PR_NUM" --repo "$REPO" --body-file "$BODY_FILE"
bash "$ROOT/scripts/sync-pr-checkboxes.sh" "$PR_NUM" || true
echo "PR #${PR_NUM}: body synced from origin/${BASE}..${BRANCH}"
