#!/usr/bin/env bash
# Return "x" if CI (backend + frontend) passes for a PR/branch, else " ".
# Usage: bash scripts/pr-ci-checkbox.sh [pr-number|branch]
#
# In GitHub Actions, GH_TOKEN is set but `gh auth status` often fails; use the token.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=gh-pr-branch.sh
source "$ROOT/scripts/gh-pr-branch.sh"
TARGET="${1:-$(git branch --show-current)}"
REPO="${GITHUB_REPOSITORY:-hrn-dev-work/SmartResearch-HQ}"
MARK=" "

export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"

gh_ready() {
  command -v gh >/dev/null 2>&1 || return 1
  gh auth status >/dev/null 2>&1 && return 0
  [[ -n "${GH_TOKEN:-}" ]]
}

if [[ "${PR_CI_CHECKBOX_MARK:-}" == "x" ]]; then
  echo "x"
  exit 0
fi

if ! gh_ready; then
  echo "$MARK"
  exit 0
fi

PR_NUM=""
if [[ "$TARGET" =~ ^[0-9]+$ ]]; then
  PR_NUM="$TARGET"
else
  PR_NUM="$(gh_pr_number_for_branch "$TARGET" "$REPO")"
fi

if [[ -n "$PR_NUM" ]]; then
  if gh pr checks "$PR_NUM" --repo "$REPO" 2>/dev/null | awk '
    $1 == "backend" || $1 == "frontend" {
      if ($2 != "pass") bad = 1
      if ($2 == "pass") ok[$1] = 1
    }
    END {
      if (!bad && ok["backend"] && ok["frontend"]) exit 0
      exit 1
    }
  '; then
    MARK="x"
  fi
elif [[ -x "$ROOT/scripts/ci-check.sh" ]] && bash "$ROOT/scripts/ci-check.sh" >/dev/null 2>&1; then
  MARK="x"
fi

echo "$MARK"
