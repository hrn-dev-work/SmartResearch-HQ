#!/usr/bin/env bash
# chore/wsl-cursor-workspace-settings: stash WIP, merge main, PR, squash merge.
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck source=gh-pr-branch.sh
source scripts/gh-pr-branch.sh

LOG="${PWD}/scripts/ship-wsl-settings.log"
exec > >(tee "$LOG") 2>&1

BRANCH="chore/wsl-cursor-workspace-settings"

echo "=== ship-wsl-settings $(date -Iseconds) ==="

git fetch origin
git checkout "$BRANCH"

# Preserve security-scanning WIP on its branch later — stash only known unrelated paths
git stash push -m "wip-security-scanning-md" -- docs/security-scanning.md 2>/dev/null || true

# Stash any other dirty state blocking merge
if [[ -n "$(git status --porcelain)" ]]; then
  echo "Dirty before merge:"
  git status --porcelain
  git stash push -u -m "wip-before-wsl-pr-merge-1780238278" -- . ":(exclude)scripts/ship-wsl-settings-pr.sh"
fi

if ! git merge-base --is-ancestor origin/main HEAD 2>/dev/null; then
  bash scripts/git-merge-main-safe.sh
fi

# CI fix + PR body overrides (same PR)
git add scripts/check-pr-tooling.sh scripts/render-pr-body.sh scripts/ship-wsl-settings-pr.sh
if ! git diff --cached --quiet; then
  git commit -F - <<'EOF'
fix(ci): check-pr-tooling body=@ false positives and WSL PR ship script

Exclude echo/comment lines from forbidden gh api body=@ scan; add render-pr-body
override for chore/wsl-cursor-workspace-settings.

---

check-pr-tooling の body=@ 誤検知を修正。WSL 設定 PR 用 ship スクリプトを追加。
EOF
fi

bash scripts/ci-check.sh
git push -u origin HEAD

bash scripts/ensure-pr.sh main
bash scripts/sync-pr-body.sh "$BRANCH" main || true

PR_NUM="$(gh_pr_number_for_branch "$BRANCH")"
URL="$(gh_pr_url_for_branch "$BRANCH")"
echo "PR: ${URL} (#${PR_NUM})"

for i in $(seq 1 80); do
  if gh pr checks "$PR_NUM" --required >/tmp/wsl-pr-checks.txt 2>&1; then
    if grep -qi fail /tmp/wsl-pr-checks.txt; then
      cat /tmp/wsl-pr-checks.txt
      exit 1
    fi
    if ! grep -qi pending /tmp/wsl-pr-checks.txt; then
      cat /tmp/wsl-pr-checks.txt
      break
    fi
  fi
  echo "CI poll $i..."
  sleep 20
done

gh pr merge "$PR_NUM" --squash --delete-branch
git fetch origin main
git checkout main
git pull --ff-only origin main
echo "DONE main=$(git rev-parse --short HEAD)"
