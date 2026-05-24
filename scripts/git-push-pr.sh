#!/usr/bin/env bash
# Push current branch and open a PR when missing.
# Usage: bash scripts/git-push-pr.sh [git-push-args...]
# Example: bash scripts/git-push-pr.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

REMOTE="${GIT_PUSH_REMOTE:-origin}"
BRANCH="$(git branch --show-current)"

if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
  echo "ERROR: push+PR helper must not run on ${BRANCH}" >&2
  exit 1
fi

git push -u "$REMOTE" HEAD "$@"
bash "$ROOT/scripts/ensure-pr.sh" main
