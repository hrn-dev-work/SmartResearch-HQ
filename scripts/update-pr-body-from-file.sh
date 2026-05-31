#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/gh-pr-branch.sh"
PR_NUM="${1:?PR number required}"
BODY_FILE="${2:?body file required}"
REPO="${GITHUB_REPOSITORY:-hrn-dev-work/SmartResearch-HQ}"
[[ -f "$BODY_FILE" ]] || { echo "ERROR: not found: $BODY_FILE" >&2; exit 1; }
bash "$ROOT/scripts/validate-pr-body.sh" --file "$BODY_FILE"
gh_pr_edit_body_safe "$PR_NUM" "$(cat "$BODY_FILE")" "$REPO"
bash "$ROOT/scripts/sync-pr-checkboxes.sh" "$PR_NUM" || true
bash "$ROOT/scripts/validate-pr-body.sh" "$PR_NUM"
echo "PR #${PR_NUM} body updated"
