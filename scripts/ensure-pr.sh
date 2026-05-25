#!/usr/bin/env bash
# Create a GitHub PR for the current branch if one does not exist yet.
# Usage: bash scripts/ensure-pr.sh [base-branch]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

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

if gh pr view --head "$BRANCH" --json number --jq .number >/dev/null 2>&1; then
  gh pr view --head "$BRANCH" --web 2>/dev/null || gh pr view --head "$BRANCH"
  exit 0
fi

TITLE="$(git log "origin/${BASE}..HEAD" --format=%s -1 2>/dev/null || git log "${BASE}..HEAD" --format=%s -1 2>/dev/null || true)"
if [[ -z "$TITLE" ]]; then
  TITLE="chore: merge ${BRANCH} into ${BASE}"
fi

BODY="$(bash "$ROOT/scripts/render-pr-body.sh" auto "$BRANCH" "$BASE")"

gh pr create --base "$BASE" --head "$BRANCH" --title "$TITLE" --body "$BODY"
echo "PR created for ${BRANCH} -> ${BASE}"
