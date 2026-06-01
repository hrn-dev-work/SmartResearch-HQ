#!/usr/bin/env bash
# One-shot: merge main into conflicted PR branches and report PR 55 CI context.
set -euo pipefail
cd "$(dirname "$0")/.."

git fetch origin

echo "=== main tip ==="
git log -1 --oneline origin/main

fix_branch() {
  local branch="$1"
  echo ""
  echo "========== $branch =========="
  git checkout -B "$branch" "origin/$branch"
  if git merge-base --is-ancestor origin/main HEAD; then
    echo "Already up to date with main"
    return 0
  fi
  if git merge origin/main -m "merge main into $branch"; then
    echo "Clean merge"
    return 0
  fi
  echo "Conflicts:"
  git diff --name-only --diff-filter=U
  return 1
}

CONFLICT_BRANCHES=(
  docs/adr-0008-ai-production-readiness
  chore/pr-demo-checkbox-na
  chore/agent-git-context
)

failed=0
for b in "${CONFLICT_BRANCHES[@]}"; do
  if ! fix_branch "$b"; then
    failed=$((failed + 1))
  fi
done

echo ""
echo "=== PR 55 branch (dependabot redis) ==="
git checkout -B dependabot/pip/backend/redis-gte-8.0.0 origin/dependabot/pip/backend/redis-gte-8.0.0
if ! git merge-base --is-ancestor origin/main HEAD; then
  git merge origin/main -m "merge main into dependabot/pip/backend/redis-gte-8.0.0" || true
fi
git diff --name-only --diff-filter=U || true
head -5 backend/requirements.txt
