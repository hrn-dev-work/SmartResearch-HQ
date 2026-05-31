#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
source "$ROOT/scripts/gh-pr-branch.sh"
export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
REPO="${GITHUB_REPOSITORY:-hrn-dev-work/SmartResearch-HQ}"
TARGET="${1:-$(git branch --show-current)}"
BASE="${2:-main}"
PR_NUM=""
if [[ "$TARGET" =~ ^[0-9]+$ ]]; then PR_NUM="$TARGET"; else PR_NUM="$(gh_pr_number_for_branch "$TARGET" "$REPO")"; fi
if [[ -z "$PR_NUM" ]]; then echo "No open PR for: ${TARGET} (skip body sync)" >&2; exit 0; fi
git fetch origin "$BASE" 2>/dev/null || true
BRANCH="$(gh pr view "$PR_NUM" --repo "$REPO" --json headRefName -q .headRefName)"
BODY_FILE="$(mktemp)"
trap 'rm -f "$BODY_FILE"' EXIT
bash "$ROOT/scripts/render-pr-body.sh" auto "$BRANCH" "$BASE" >"$BODY_FILE"
bash "$ROOT/scripts/validate-pr-body.sh" --file "$BODY_FILE"
gh_pr_edit_body_safe "$PR_NUM" "$(cat "$BODY_FILE")" "$REPO"
bash "$ROOT/scripts/sync-pr-checkboxes.sh" "$PR_NUM" || true
bash "$ROOT/scripts/validate-pr-body.sh" "$PR_NUM"
echo "PR #${PR_NUM}: body synced (bilingual template)"
