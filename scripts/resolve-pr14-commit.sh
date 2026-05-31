#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

git add \
  frontend/src/app/globals.css \
  frontend/src/app/page.tsx \
  frontend/src/components/AboutDemoDialog.tsx \
  frontend/src/lib/ui-classes.ts \
  scripts/agent-push.sh \
  scripts/resolve-pr14-merge.sh \
  scripts/resolve-pr14-commit.sh

if [[ -n "$(git diff --name-only --diff-filter=U)" ]]; then
  echo "Still unmerged:" >&2
  git diff --name-only --diff-filter=U >&2
  exit 1
fi

if [[ -f .git/MERGE_HEAD ]]; then
  git commit -F - <<'EOF'
merge main: keep i18n UI from main and deploy presets on agent-push

Resolve PR #14 conflicts with main (#15): adopt main frontend i18n/layout,
combine portfolio-docs-deploy and production-local-setup in agent-push.sh.

---

PR #14 と main (#15) のコンフリクト解消。フロント i18n は main を採用、
agent-push は両 preset を維持。
EOF
else
  git diff --cached --quiet && exit 0
  git commit -m "fix: resolve PR #14 merge conflicts with main"
fi

bash scripts/ci-check.sh
git push origin docs/portfolio-deploy-live
bash scripts/sync-pr-body.sh docs/portfolio-deploy-live main 2>/dev/null || true
gh pr view 14 --json url,mergeable,mergeStateStatus -q '.'
