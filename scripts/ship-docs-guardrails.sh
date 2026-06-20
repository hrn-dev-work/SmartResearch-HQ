#!/usr/bin/env bash
# Ship docs/guardrails-engineering-principles: commit, PR, merge when CI green.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
# shellcheck source=agent-local-log.sh
source "$(dirname "$0")/agent-local-log.sh"

LOG="$(agent_local_log_path ship-docs-guardrails.log)"
: >"$LOG"
exec > >(tee -a "$LOG") 2>&1

echo "== $(date -Iseconds) ship-docs-guardrails =="

git merge --abort 2>/dev/null || true
git rebase --abort 2>/dev/null || true
git checkout -- scripts/git-add-safe.sh 2>/dev/null || true

git fetch origin
git checkout main
git pull --ff-only origin main

BRANCH="docs/guardrails-engineering-principles"
git checkout -B "$BRANCH"

# Remove agent junk if present
rm -f .agent-*.sh .agent-*.txt hello-wsl.txt scripts/.wsl-sync-test 2>/dev/null || true

bash scripts/git-add-safe.sh

if git diff --cached --quiet; then
  echo "Nothing to commit — verify files exist on disk" >&2
  git status -sb
  exit 1
fi

git commit -m "$(cat <<'EOF'
docs: security guardrails, engineering principles, and PR tooling

Add ADR-0006 (OWASP/IPA security), ADR-0007 (YAGNI, fail-fast, testability,
Why-not-What), agent security/engineering docs, git-hooks guide, and PR body
validation with docs cross-link checks.

---

セキュリティ規約・4つの工学原則・PR 本文 guardrails を明文化。
EOF
)"

bash scripts/ci-check.sh

git push -u origin HEAD

bash scripts/ensure-pr.sh main
bash scripts/sync-pr-body.sh "$BRANCH" main || true

PR="$(gh pr list --head "$BRANCH" --state open --json number -q '.[0].number')"
echo "PR #${PR}"

echo "Waiting for CI..."
for i in $(seq 1 50); do
  if gh pr checks "$PR" 2>/dev/null | grep -E 'fail|pending' | grep -qv 'ensure-pull-request'; then
    sleep 30
  else
    break
  fi
done

gh pr checks "$PR" || true

if gh pr checks "$PR" 2>&1 | grep -E '^[^ ]+[[:space:]]+fail' | grep -qv ensure-pull-request; then
  echo "CI FAILED" >&2
  exit 1
fi

gh pr merge "$PR" --squash --delete-branch

git checkout main
git pull --ff-only origin main

echo "DONE main=$(git rev-parse --short HEAD)"
gh pr view "$PR" --json url,mergedAt,state
