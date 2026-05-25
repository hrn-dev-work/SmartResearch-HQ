#!/usr/bin/env bash
# Bootstrap: first PR for git-workflow / GitHub templates (run once from default branch).
# Usage: bash scripts/git-first-pr.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BASE="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo main)"
BRANCH="chore/git-workflow-setup"

if [[ "$(git branch --show-current)" == "$BASE" ]]; then
  git checkout -b "$BRANCH"
else
  git checkout "$BRANCH" 2>/dev/null || git checkout -b "$BRANCH"
fi

git add -A
if git diff --cached --quiet; then
  echo "Nothing to commit."
else
  git commit -m "$(cat <<'EOF'
chore: add git workflow, GitHub templates, and agent settings

Stop direct commits to main; unify on branch → PR → squash merge.

---

main 直コミットをやめ、作業ブランチ→PR→squash マージに統一する。
Issue/PR テンプレ、ラベル定義、commit-pr-style スキル、git-workflow 規約を含む。
EOF
)"
fi

git push -u origin HEAD
gh repo set-default hrn-dev-work/SmartResearch-HQ 2>/dev/null || true
python3 scripts/sync-github-labels.py || true

if gh pr view --head "$BRANCH" >/dev/null 2>&1; then
  gh pr view --head "$BRANCH" --json url -q .url
else
  gh pr create --base "$BASE" --title "chore: add git workflow, GitHub templates, and agent settings" --body "$(cat <<'EOF'
## Summary

- Add git-workflow docs, commit-pr-style skill, CI, and GitHub templates _(Git 運用規約・テンプレ・スキル追加)_
- Track .cursor rules needed for GitHub workflow _(.cursor / AGENTS.md を追跡対象に)_

## Test plan

- [ ] `bash scripts/ci-check.sh`
- [ ] CI green

## Related

- Branch: `chore/git-workflow-setup`
EOF
)"
fi

echo "Done. Merge with: gh pr merge --squash --delete-branch"
