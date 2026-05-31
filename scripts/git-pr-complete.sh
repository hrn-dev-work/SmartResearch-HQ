#!/usr/bin/env bash
# Canonical "PR作成まで" for agents and humans. One entry point.
# Usage: bash scripts/git-pr-complete.sh [commit-message subject if auto-commit needed]

set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck source=gh-pr-branch.sh
source scripts/gh-pr-branch.sh

bash scripts/git-agent-context.sh --strict

BASE="${GIT_PR_BASE:-main}"
BRANCH="$(git branch --show-current)"
COMMIT_SUBJECT="${1:-}"

if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
  echo "ERROR: run from a feature branch, not ${BRANCH}." >&2
  exit 1
fi

git fetch origin

if [[ -f .git/MERGE_HEAD ]]; then
  echo "Finishing pending merge..."
  bash scripts/resolve-merge-main-keep-i18n.sh
  exit $?
fi

if ! git merge-base --is-ancestor origin/main HEAD 2>/dev/null; then
  echo "Branch behind origin/main — merging first..."
  bash scripts/git-merge-main-safe.sh
fi

if [[ -n "$(git status --porcelain)" ]]; then
  bash scripts/git-add-safe.sh
  if ! git diff --cached --quiet; then
    if [[ -n "$COMMIT_SUBJECT" ]]; then
      git commit -m "$COMMIT_SUBJECT"
    else
      git commit -m "chore: sync local changes before PR"
    fi
  fi
fi

bash scripts/ci-check.sh

git push -u origin HEAD
bash scripts/ensure-pr.sh "$BASE"
bash scripts/sync-pr-body.sh "$BRANCH" "$BASE" || true

PR_NUM="$(gh_pr_number_for_branch "$BRANCH")"
URL="$(gh_pr_url_for_branch "$BRANCH")"
if [[ -n "$URL" ]]; then
  echo "PR: ${URL} (#${PR_NUM})"
else
  echo "ERROR: PR URL not found. Run: gh pr list --head ${BRANCH}" >&2
  exit 1
fi
