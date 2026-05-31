#!/usr/bin/env bash
# feat/production-local-setup: commit, PR, CI wait, squash merge to main.
set -euo pipefail
cd "$(dirname "$0")/.."
LOG="${PWD}/agent-pr-merge.log"
exec > >(tee -a "$LOG") 2>&1

echo "=== $(date -Iseconds) branch=$(git branch --show-current) ==="
git fetch origin

if ! git merge-base --is-ancestor origin/main HEAD 2>/dev/null; then
  bash scripts/git-merge-main-safe.sh
fi

bash scripts/git-add-safe.sh
if ! git diff --cached --quiet; then
  git commit -F - <<'EOF'
feat(production): local setup, i18n UI, and dev viewport scripts

Add production local start script and docs. Wire frontend JA/EN locale
(messages, middleware, toggle), UI layout fixes, and Playwright viewport
checks plus stop-next-dev for WSL port 3000.

---

本番ローカル起動スクリプトとドキュメントを追加。フロントの JA/EN 多言語、
UI 調整、WSL 向け dev 停止・画面幅チェック用スクリプトを含む。
EOF
fi

bash scripts/ci-check.sh
bash scripts/git-pr-complete.sh

PR_NUM="$(bash -c 'source scripts/gh-pr-branch.sh; gh_pr_number_for_branch feat/production-local-setup')"
echo "PR_NUM=${PR_NUM}"

for i in $(seq 1 60); do
  state="$(gh pr checks "$PR_NUM" --required 2>/dev/null | awk 'NR>1 {print $2}' | sort -u | tr '\n' ' ')"
  echo "CI poll $i: ${state:-pending}"
  if echo "$state" | grep -q fail; then
    gh pr checks "$PR_NUM" || true
    exit 1
  fi
  if echo "$state" | grep -qvE 'pending|skipping'; then
    if ! echo "$state" | grep -q pending; then
      break
    fi
  fi
  sleep 15
done

gh pr merge "$PR_NUM" --squash --delete-branch
git fetch origin main
echo "MERGED main=$(git rev-parse --short origin/main)"
gh pr view "$PR_NUM" --json url,state,mergedAt -q '.'
