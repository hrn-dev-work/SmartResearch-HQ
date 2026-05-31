#!/usr/bin/env bash
# Warn when staged changes are docs-only but the branch name does not suggest docs work.
# Non-blocking (exit 0). Usage: called from git-add-safe.sh after staging.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

mapfile -t STAGED < <(git diff --cached --name-only 2>/dev/null || true)
[[ ${#STAGED[@]} -eq 0 ]] && exit 0

doc_only=1
for f in "${STAGED[@]}"; do
  case "$f" in
    README.md | frontend/README.md | docs/*.md | docs/*/*.md) ;;
    *) doc_only=0; break ;;
  esac
done
[[ "$doc_only" -eq 0 ]] && exit 0

BRANCH="$(git branch --show-current)"
if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
  exit 0
fi

if [[ "$BRANCH" =~ ^(docs/|chore/docs|feat/docs) ]]; then
  exit 0
fi

echo "WARN: staged files are docs-only but branch is '${BRANCH}'." >&2
echo "      Prefer: bash scripts/git-start-branch.sh docs/<short-topic>" >&2
echo "      (Mixed PRs on unrelated branch names are hard to review.)" >&2
exit 0
