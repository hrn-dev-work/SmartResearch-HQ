#!/usr/bin/env bash
# Start work on a new branch from up-to-date default branch.
# Usage: bash scripts/git-start-branch.sh feat/wbs-2-3-sheets-export

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: bash scripts/git-start-branch.sh <branch-name>" >&2
  exit 1
fi

BRANCH="$1"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
  echo "ERROR: work branch must not be main/master" >&2
  exit 1
fi

DEFAULT_BRANCH="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || true)"
if [[ -z "$DEFAULT_BRANCH" ]]; then
  DEFAULT_BRANCH="main"
fi

if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  echo "ERROR: branch already exists locally: $BRANCH" >&2
  exit 1
fi

git fetch origin "$DEFAULT_BRANCH" 2>/dev/null || true
git checkout "$DEFAULT_BRANCH"
git pull --ff-only origin "$DEFAULT_BRANCH" 2>/dev/null || git pull --ff-only || true
git checkout -b "$BRANCH"

echo "Ready on branch: $BRANCH (from $DEFAULT_BRANCH)"
