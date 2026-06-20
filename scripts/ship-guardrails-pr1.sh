#!/usr/bin/env bash
# PR1: CONTEXT + agents + ADR 0006/0007 + security-scanning links → squash merge.
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck source=gh-pr-branch.sh
source "$(dirname "$0")/gh-pr-branch.sh"
# shellcheck source=agent-local-log.sh
source "$(dirname "$0")/agent-local-log.sh"

LOG="$(agent_local_log_path ship-guardrails-pr1.log)"
: >"$LOG"
exec > >(tee -a "$LOG") 2>&1

BRANCH="docs/guardrails-engineering-principles"

echo "=== PR1 ship $(date -Iseconds) ==="

git stash push -m "agent-junk" -- .agent-pr-result.txt .agent-*.sh .agent-*.txt 2>/dev/null || true
git restore frontend/.gitignore frontend/package.json 2>/dev/null || true

git fetch origin
git checkout main
git pull --ff-only origin main
git checkout -B "$BRANCH"

bash scripts/materialize-guardrails-docs.sh

# Mark rollout S0.1 done after materialize
sed -i 's/| S0.1 | ADR 0006 + CONTEXT security sections merged | pending |/| S0.1 | ADR 0006 + CONTEXT security sections merged | done |/' \
  docs/agents/security-rollout-tasks.md
install -D docs/agents/security-rollout-tasks.md \
  scripts/guardrails-docs-staging/docs/agents/security-rollout-tasks.md

git add \
  CONTEXT.md \
  README.md \
  docs/agents \
  docs/adr/README.md \
  docs/adr/0006-security-guardrails-public-standards.md \
  docs/adr/0007-engineering-principles-for-agents.md \
  docs/security-scanning.md \
  scripts/guardrails-docs-staging \
  scripts/materialize-guardrails-docs.sh \
  scripts/render-pr-body.sh \
  scripts/ship-guardrails-pr1.sh \
  scripts/ship-guardrails-pr2.sh \
  scripts/ship-two-guardrails-prs.sh

if git diff --cached --quiet; then
  echo "ERROR: nothing staged for PR1" >&2
  exit 1
fi

git commit -F - <<'EOF'
docs: security guardrails, engineering principles, ADR 0006/0007

Add CONTEXT security sections, agent docs (OWASP/IPA, YAGNI/fail-fast/testability),
and ADR 0006/0007. Staging bundle avoids UNC/WSL desync on doc paths.

---

セキュリティ規約・4原則・ADR 0006/0007 をリポ上で完結。WSL 同期用 staging 付き。
EOF

bash scripts/ci-check.sh
git push -u origin HEAD --force-with-lease
bash scripts/ensure-pr.sh main
bash scripts/sync-pr-body.sh "$BRANCH" main || true

PR_NUM="$(gh_pr_number_for_branch "$BRANCH")"
URL="$(gh_pr_url_for_branch "$BRANCH")"
echo "PR1: ${URL} (#${PR_NUM})"

for i in $(seq 1 80); do
  if gh pr checks "$PR_NUM" --required >/tmp/pr1-checks.txt 2>&1; then
    if grep -qi fail /tmp/pr1-checks.txt; then
      cat /tmp/pr1-checks.txt
      exit 1
    fi
    if ! grep -qi pending /tmp/pr1-checks.txt; then
      cat /tmp/pr1-checks.txt
      break
    fi
  fi
  echo "PR1 CI poll $i: waiting..."
  sleep 20
done

gh pr merge "$PR_NUM" --squash --delete-branch
git fetch origin main
git checkout main
git pull --ff-only origin main
echo "PR1 merged main=$(git rev-parse --short HEAD)"
