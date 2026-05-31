#!/usr/bin/env bash
# Finish an in-progress merge: keep branch (HEAD) versions of conflicted files.
set -euo pipefail
cd "$(dirname "$0")/.."
BRANCH="$(git branch --show-current)"

if [[ ! -f .git/MERGE_HEAD ]]; then
  echo "No merge in progress." >&2
  exit 1
fi

UNMERGED="$(git diff --name-only --diff-filter=U)"
if [[ -z "$UNMERGED" ]]; then
  echo "No unmerged paths."
else
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    echo "Resolve (ours): $f"
    git checkout --ours -- "$f"
    git add -- "$f"
  done <<<"$UNMERGED"
fi

git add -u

git commit -m "merge main: keep i18n UI and bilingual deploy guide"
echo "Merge commit: $(git rev-parse --short HEAD)"

# Allow follow-up fix commits before CI
git add frontend/src/lib/locale.ts frontend/src/components/LocaleToggle.tsx scripts/ci-check.sh 2>/dev/null || true
if ! git diff --cached --quiet 2>/dev/null; then
  git commit -m "fix(frontend): satisfy eslint for locale cookie write" || true
fi

bash scripts/ci-check.sh
bash scripts/git-ship.sh pr
bash scripts/sync-pr-body.sh "$BRANCH" main || true
# shellcheck source=gh-pr-branch.sh
source "$(dirname "$0")/gh-pr-branch.sh"
PR_NUM="$(gh_pr_number_for_branch "$BRANCH")"
if [[ -n "$PR_NUM" ]]; then
  gh pr view "$PR_NUM" --json url,number,title -q '"\(.url) (#\(.number)) \(.title)"'
else
  gh_pr_url_for_branch "$BRANCH"
fi
