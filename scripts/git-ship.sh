#!/usr/bin/env bash
# Push branch and optionally open/sync a PR. Agent entry point for "push until PR".
# Usage:
#   bash scripts/git-ship.sh push              # push only
#   bash scripts/git-ship.sh pr [base]         # push + ensure PR + post-workflow
#   bash scripts/git-ship.sh pr-url [base]      # print PR URL (create if missing)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
# shellcheck source=gh-pr-branch.sh
source "$ROOT/scripts/gh-pr-branch.sh"

MODE="${1:-pr}"
BASE="${2:-main}"
BRANCH="$(git branch --show-current)"
REMOTE="${GIT_PUSH_REMOTE:-origin}"

if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
  echo "ERROR: git-ship must not run on ${BRANCH}. Create a work branch first." >&2
  echo "  bash scripts/git-start-branch.sh feat/your-task" >&2
  exit 1
fi

if [[ "$MODE" == "pr-url" ]]; then
  URL="$(gh_pr_url_for_branch "$BRANCH")"
  if [[ -n "$URL" ]]; then
    echo "$URL"
    exit 0
  fi
  MODE="pr"
fi

git fetch origin
if [[ "$MODE" == "pr" ]] && ! git merge-base --is-ancestor origin/main HEAD 2>/dev/null; then
  echo "WARN: ${BRANCH} is behind origin/main. Prefer: bash scripts/git-pr-complete.sh" >&2
fi

git push -u "$REMOTE" HEAD "${@:3}"

case "$MODE" in
  push)
    echo "Pushed ${BRANCH} -> ${REMOTE}"
    if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
      bash "$ROOT/scripts/sync-pr-body.sh" "$BRANCH" "$BASE" 2>/dev/null || true
    fi
    ;;
  pr)
    bash "$ROOT/scripts/ensure-pr.sh" "$BASE"
    bash "$ROOT/scripts/post-workflow.sh" || true
    PR_NUM="$(gh_pr_number_for_branch "$BRANCH")"
    URL="$(gh_pr_url_for_branch "$BRANCH")"
    if [[ -n "$PR_NUM" && -n "$URL" ]]; then
      TITLE="$(gh pr view "$PR_NUM" --json title -q .title 2>/dev/null || true)"
      echo "PR: ${URL} (#${PR_NUM}${TITLE:+ ${TITLE}})"
    elif [[ -n "$URL" ]]; then
      echo "PR: ${URL}"
    else
      echo "WARN: push OK but PR URL not found — run: gh pr list --head ${BRANCH}" >&2
    fi
    ;;
  *)
    echo "Usage: bash scripts/git-ship.sh push|pr|pr-url [base] [git-push-args...]" >&2
    exit 1
    ;;
esac
