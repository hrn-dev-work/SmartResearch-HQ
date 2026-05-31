#!/usr/bin/env bash
# Sync CI-related checkboxes in a PR body (backend/frontend/ci-check lines).
# Usage: bash scripts/sync-pr-checkboxes.sh [pr-number|branch]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
# shellcheck source=gh-pr-branch.sh
source "$ROOT/scripts/gh-pr-branch.sh"

export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
REPO="${GITHUB_REPOSITORY:-hrn-dev-work/SmartResearch-HQ}"
TARGET="${1:-$(git branch --show-current)}"
PR_NUM=""

if [[ "$TARGET" =~ ^[0-9]+$ ]]; then
  PR_NUM="$TARGET"
else
  PR_NUM="$(gh_pr_number_for_branch "$TARGET" "$REPO")"
fi

if [[ -z "$PR_NUM" ]]; then
  echo "No open PR for: ${TARGET}" >&2
  exit 1
fi

MARK="$(bash "$ROOT/scripts/pr-ci-checkbox.sh" "$PR_NUM")"
BODY="$(gh pr view "$PR_NUM" --repo "$REPO" --json body -q .body)"

NEW_BODY="$(python3 -c "
import re, sys
mark, body = sys.argv[1], sys.argv[2]

def sync_line(line):
    lower = line.lower()
    if 'ci-check.sh' in lower or ('backend' in lower and 'frontend' in lower) or re.search(r'\\bci green\\b', lower):
        return re.sub(r'^([*-]) \\[[ xX]\\]', rf'\\1 [{mark}]', line)
    return line

print('\\n'.join(sync_line(line) for line in body.splitlines()))
" "$MARK" "$BODY")"

if [[ "$BODY" == "$NEW_BODY" ]]; then
  echo "PR #${PR_NUM}: checkboxes already up to date (CI mark='${MARK}')"
  exit 0
fi

TMP="$(mktemp)"
ERR="$(mktemp)"
trap 'rm -f "$TMP" "$ERR"' EXIT
python3 -c "import json,sys; print(json.dumps({'body': sys.argv[1]}))" "$NEW_BODY" >"$TMP"
if ! gh api "repos/${REPO}/pulls/${PR_NUM}" -X PATCH --input "$TMP" 2>"$ERR"; then
  if grep -q "not permitted to create or approve pull requests" "$ERR" 2>/dev/null; then
    cat >&2 <<'EOF'
ERROR: GitHub Actions cannot update PR bodies with the default GITHUB_TOKEN.

Fix (choose one):
  1. Org/repo: Settings → Actions → allow GitHub Actions to create or approve pull requests.
  2. Add repository secret GH_PR_SYNC_TOKEN (fine-grained PAT: Pull requests Read and write).
     The CI sync job uses: secrets.GH_PR_SYNC_TOKEN || github.token

See docs/git-workflow.md §「PR 本文の CI チェック自動同期」.
EOF
  else
    cat "$ERR" >&2
  fi
  exit 1
fi
echo "PR #${PR_NUM}: synced CI checkboxes (mark='${MARK}')"
