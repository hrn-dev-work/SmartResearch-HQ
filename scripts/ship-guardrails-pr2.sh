#!/usr/bin/env bash
# PR2: git-hooks doc + extended check-pr-tooling + update-pr-body-from-file → squash merge.
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck source=gh-pr-branch.sh
source "$(dirname "$0")/gh-pr-branch.sh"
# shellcheck source=agent-local-log.sh
source "$(dirname "$0")/agent-local-log.sh"

LOG="$(agent_local_log_path ship-guardrails-pr2.log)"
: >"$LOG"
exec > >(tee -a "$LOG") 2>&1

BRANCH="chore/pr-tooling-guardrails"

echo "=== PR2 ship $(date -Iseconds) ==="

git stash push -m "agent-junk" -- .agent-pr-result.txt .agent-*.sh .agent-*.txt 2>/dev/null || true
git restore frontend/.gitignore frontend/package.json 2>/dev/null || true

git fetch origin
git checkout main
git pull --ff-only origin main
git checkout -B "$BRANCH"

PR2=(
  docs/git-hooks.md
  scripts/check-pr-tooling.sh
  scripts/update-pr-body-from-file.sh
  scripts/render-pr-body.sh
  scripts/ship-guardrails-pr2.sh
  scripts/ship-two-guardrails-prs.sh
)

missing=0
for f in "${PR2[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "MISSING: $f" >&2
    missing=1
  fi
done
[[ "$missing" -eq 0 ]] || exit 1

git add "${PR2[@]}"

if git diff --cached --quiet; then
  echo "ERROR: nothing staged for PR2 (already on main?)" >&2
  git diff main -- "${PR2[@]}" || true
  exit 1
fi

git commit -F - <<'EOF'
chore: PR tooling guardrails (git-hooks doc, check-pr-tooling)

Document local pre-commit/post-push hooks and extend check-pr-tooling self-check
for validate-pr-body, crosslink script, sync-pr-body, and update-pr-body-from-file.

---

git-hooks ドキュメントと check-pr-tooling 拡張で PR 本文・crosslink ガードレールを完結。
EOF

bash scripts/ci-check.sh
git push -u origin HEAD --force-with-lease
bash scripts/ensure-pr.sh main
bash scripts/sync-pr-body.sh "$BRANCH" main || true

PR_NUM="$(gh_pr_number_for_branch "$BRANCH")"
URL="$(gh_pr_url_for_branch "$BRANCH")"
echo "PR2: ${URL} (#${PR_NUM})"

for i in $(seq 1 80); do
  if gh pr checks "$PR_NUM" --required >/tmp/pr2-checks.txt 2>&1; then
    if grep -qi fail /tmp/pr2-checks.txt; then
      cat /tmp/pr2-checks.txt
      exit 1
    fi
    if ! grep -qi pending /tmp/pr2-checks.txt; then
      cat /tmp/pr2-checks.txt
      break
    fi
  fi
  echo "PR2 CI poll $i: waiting..."
  sleep 20
done

gh pr merge "$PR_NUM" --squash --delete-branch
git fetch origin main
git checkout main
git pull --ff-only origin main
echo "PR2 merged main=$(git rev-parse --short HEAD)"
