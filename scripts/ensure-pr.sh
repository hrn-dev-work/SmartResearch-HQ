#!/usr/bin/env bash
# Create a GitHub PR for the current branch if one does not exist yet.
# Usage: bash scripts/ensure-pr.sh [base-branch]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
# shellcheck source=gh-pr-branch.sh
source "$ROOT/scripts/gh-pr-branch.sh"

BASE="${1:-main}"
BRANCH="$(git branch --show-current)"

if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
  exit 0
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "WARN: gh CLI not found — skip auto PR (install: https://cli.github.com/)" >&2
  exit 0
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "WARN: gh not authenticated — run: gh auth login" >&2
  exit 0
fi

PR_NUM="$(gh_pr_number_for_branch "$BRANCH")"
if [[ -n "$PR_NUM" ]]; then
  bash "$ROOT/scripts/sync-pr-body.sh" "$BRANCH" "$BASE" || true
  gh pr view "$PR_NUM" --web 2>/dev/null || gh pr view "$PR_NUM"
  exit 0
fi

TITLE="$(bash "$ROOT/scripts/render-pr-title.sh" "$BASE" "$BRANCH")"
BODY="$(bash "$ROOT/scripts/render-pr-body.sh" auto "$BRANCH" "$BASE")"

gh pr create --base "$BASE" --head "$BRANCH" --title "$TITLE" --body "$BODY"
PR_NUM="$(gh_pr_number_for_branch "$BRANCH")"
bash "$ROOT/scripts/sync-pr-checkboxes.sh" "$PR_NUM" || true
echo "PR created for ${BRANCH} -> ${BASE} (#${PR_NUM})"
