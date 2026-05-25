#!/usr/bin/env bash
# Sync CI-related checkboxes in a PR body (backend/frontend/ci-check lines).
# Usage: bash scripts/sync-pr-checkboxes.sh [pr-number|branch]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TARGET="${1:-$(git branch --show-current)}"
PR_NUM=""

if [[ "$TARGET" =~ ^[0-9]+$ ]]; then
  PR_NUM="$TARGET"
else
  PR_NUM="$(gh pr view --head "$TARGET" --json number -q .number 2>/dev/null || true)"
fi

if [[ -z "$PR_NUM" ]]; then
  echo "No open PR for: ${TARGET}" >&2
  exit 1
fi

MARK="$(bash "$ROOT/scripts/pr-ci-checkbox.sh" "$PR_NUM")"
BODY="$(gh pr view "$PR_NUM" --json body -q .body)"

NEW_BODY="$(python3 -c "
import re, sys
mark, body = sys.argv[1], sys.argv[2]
checked = f'- [{mark}]'

def sync_line(line):
    lower = line.lower()
    if 'ci-check.sh' in lower:
        return re.sub(r'^- \[[ xX]\]', checked, line)
    if 'backend' in lower and 'frontend' in lower:
        return re.sub(r'^- \[[ xX]\]', checked, line)
    if re.search(r'\\bci green\\b', lower):
        return re.sub(r'^- \[[ xX]\]', checked, line)
    return line

print('\\n'.join(sync_line(line) for line in body.splitlines()))
" "$MARK" "$BODY")"

if [[ "$BODY" == "$NEW_BODY" ]]; then
  echo "PR #${PR_NUM}: checkboxes already up to date (CI mark='${MARK}')"
  exit 0
fi

REPO="${GITHUB_REPOSITORY:-hrn-dev-work/SmartResearch-HQ}"
TMP="$(mktemp)"
python3 -c "import json, sys; print(json.dumps({\"body\": sys.argv[1]}))" "$NEW_BODY" >"$TMP"
gh api "repos/${REPO}/pulls/${PR_NUM}" -X PATCH --input "$TMP"
rm -f "$TMP"
echo "PR #${PR_NUM}: synced CI checkboxes (mark='${MARK}')"
