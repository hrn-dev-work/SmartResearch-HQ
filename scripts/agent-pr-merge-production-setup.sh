#!/usr/bin/env bash
# feat/production-local-setup: stage i18n, commit, PR, CI wait, squash merge to main.
set -euo pipefail
cd "$(dirname "$0")/.."
LOG="${PWD}/agent-pr-merge.log"
exec > >(tee -a "$LOG") 2>&1

echo "=== $(date -Iseconds) branch=$(git branch --show-current) ==="
git fetch origin

if ! git merge-base --is-ancestor origin/main HEAD 2>/dev/null; then
  bash scripts/git-merge-main-safe.sh 2>/dev/null || git merge origin/main
fi

# Stage i18n + dev scripts (explicit paths; some may be skipped by git-add-safe incorrectly)
git add \
  frontend/src/lib/messages \
  frontend/src/lib/locale.ts \
  frontend/src/lib/format-message.ts \
  frontend/src/lib/ui-classes.ts \
  frontend/src/middleware.ts \
  frontend/src/components/LocaleProvider.tsx \
  frontend/src/components/LocaleToggle.tsx \
  frontend/src/components/AboutDemoDialog.tsx \
  frontend/src/components/AboutDemoTrigger.tsx \
  frontend/src/components/Header.tsx \
  frontend/src/components/StatusBadge.tsx \
  frontend/src/app/layout.tsx \
  frontend/src/app/page.tsx \
  frontend/src/app/globals.css \
  frontend/src/app/review \
  frontend/src/lib/asin.ts \
  frontend/scripts \
  scripts/gh-pr-branch.sh \
  scripts/sync-pr-body.sh \
  scripts/stop-next-dev.sh \
  frontend/.gitignore \
  2>/dev/null || true

bash scripts/git-add-safe.sh

if ! git diff --cached --quiet; then
  git commit -F - <<'EOF'
feat(frontend): i18n UI, viewport checks, and production local scripts

Wire JA/EN messages, locale middleware, header toggle, and layout fixes.
Add frontend dev scripts (viewport check, stop-next-dev) and gh PR helpers.

---

フロントの JA/EN 多言語・レイアウト修正と、dev 用スクリプト・PR 補助を追加。
EOF
fi

bash scripts/ci-check.sh
bash scripts/git-ship.sh pr main

PR_NUM="$(bash -c 'source scripts/gh-pr-branch.sh; gh_pr_number_for_branch feat/production-local-setup')"
echo "PR_NUM=${PR_NUM}"
URL="$(bash -c 'source scripts/gh-pr-branch.sh; gh_pr_url_for_branch feat/production-local-setup')"
echo "PR_URL=${URL}"

for i in $(seq 1 60); do
  if ! gh pr checks "$PR_NUM" --required >/tmp/pr-checks.txt 2>&1; then
    echo "CI poll $i: waiting..."
    sleep 15
    continue
  fi
  if grep -qi fail /tmp/pr-checks.txt; then
    cat /tmp/pr-checks.txt
    exit 1
  fi
  if ! grep -qi pending /tmp/pr-checks.txt; then
    cat /tmp/pr-checks.txt
    break
  fi
  echo "CI poll $i: pending"
  sleep 15
done

gh pr merge "$PR_NUM" --squash --delete-branch
git fetch origin main
echo "MERGED main=$(git rev-parse --short origin/main)"
gh pr view "$PR_NUM" --json url,state,mergedAt -q '.'
