#!/usr/bin/env bash
# Merge origin/main into current branch. Auto-resolve known UI/docs conflicts with --ours.
# Usage: bash scripts/git-merge-main-safe.sh

set -euo pipefail
cd "$(dirname "$0")/.."

git fetch origin

if git merge-base --is-ancestor origin/main HEAD 2>/dev/null; then
  echo "Already includes origin/main."
  exit 0
fi

if [[ -f .git/MERGE_HEAD ]]; then
  echo "Merge already in progress. Run: bash scripts/resolve-merge-main-keep-i18n.sh" >&2
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "ERROR: commit or stash local changes before merging main." >&2
  echo "  bash scripts/git-add-safe.sh && git commit -m '...'" >&2
  exit 1
fi

echo "Merging origin/main..."
if git merge origin/main; then
  echo "Fast-forward or clean merge."
  exit 0
fi

while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  echo "Resolve (ours): $f"
  git checkout --ours -- "$f"
  git add -- "$f"
done < <(git diff --name-only --diff-filter=U)

git add -u
git commit -m "merge main: keep branch versions for portfolio and i18n paths"
echo "Merge commit: $(git rev-parse --short HEAD)"
