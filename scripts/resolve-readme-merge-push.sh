#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
LOG=merge-result.txt
exec > >(tee -a "$LOG") 2>&1

echo "=== resolve-readme-merge-push $(date -Iseconds) ==="

git fetch origin
git checkout chore/gitignore-local-agent-tooling

if [ -f .git/MERGE_HEAD ]; then
  echo "Merge already in progress."
elif git merge-base --is-ancestor origin/main HEAD 2>/dev/null; then
  echo "origin/main already merged into HEAD."
else
  git merge origin/main || true
fi

if [ -f .git/MERGE_HEAD ] || git diff --name-only --diff-filter=U | grep -q .; then
  if git diff --name-only --diff-filter=U | grep -qv '^README.md$'; then
    echo "ERROR: conflicts outside README.md:"
    git diff --name-only --diff-filter=U
    exit 1
  fi
  git checkout --ours README.md
  git add README.md
  git commit -m "merge main: keep portfolio README"
fi

git push origin chore/gitignore-local-agent-tooling
git status -sb
git log -1 --oneline
echo "=== done ==="
