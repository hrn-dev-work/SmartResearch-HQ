#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
git checkout chore/agent-git-context
git add scripts/git-pr-complete.sh
if git diff --cached --quiet; then echo "no change to commit"; else
  git commit -m "fix(scripts): do not auto-commit untracked files in pr-complete" \
    -m "Only run git-add-safe when tracked files differ; avoids picking up local one-off scripts."
fi
export GIT_PR_FAST_DOCS=1
printf '%s\n' chore/agent-git-context > .git/agent-expected-branch
bash scripts/git-pr-docs-only.sh
