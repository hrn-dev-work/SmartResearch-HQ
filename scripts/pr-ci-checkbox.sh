#!/usr/bin/env bash
# Return "x" if CI (backend + frontend) passes for a PR/branch, else " ".
# Usage: bash scripts/pr-ci-checkbox.sh [pr-number|branch]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${1:-$(git branch --show-current)}"
MARK=" "

if ! command -v gh >/dev/null 2>&1 || ! gh auth status >/dev/null 2>&1; then
  echo "$MARK"
  exit 0
fi

PR_NUM=""
if [[ "$TARGET" =~ ^[0-9]+$ ]]; then
  PR_NUM="$TARGET"
elif gh pr view --head "$TARGET" --json number -q .number >/dev/null 2>&1; then
  PR_NUM="$(gh pr view --head "$TARGET" --json number -q .number)"
fi

if [[ -n "$PR_NUM" ]]; then
  if gh pr checks "$PR_NUM" 2>/dev/null | awk '
    ($1 == "backend" || $1 == "frontend") { seen = 1; if ($2 != "pass") bad = 1 }
    END { exit (seen && !bad) ? 0 : 1 }
  '; then
    MARK="x"
  fi
elif [[ -x "$ROOT/scripts/ci-check.sh" ]] && bash "$ROOT/scripts/ci-check.sh" >/dev/null 2>&1; then
  MARK="x"
fi

echo "$MARK"
