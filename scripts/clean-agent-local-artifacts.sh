#!/usr/bin/env bash
# Remove stale agent debug files at repo root; optionally purge .agent-local/.
#
# Usage:
#   bash scripts/clean-agent-local-artifacts.sh          # repo-root junk only
#   bash scripts/clean-agent-local-artifacts.sh --all    # root + .agent-local/
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# shellcheck source=agent-local-log.sh
source "$ROOT/scripts/agent-local-log.sh"

removed=0
rm_one() {
  local f="$1"
  if [[ -f "$f" ]]; then
    rm -f "$f"
    echo "removed: $f"
    removed=$((removed + 1))
  fi
}

agent_clean_root_junk

for f in \
  _fix-main.log _fix-main2.log \
  .ship-closeout.log \
  dependabot-pr-log.txt pr-create-log.txt run-log.txt \
  .pr13-merge-log.txt .pr13-push-log.txt \
  .sync-pr-log.txt \
  push-pr14.log resolve-pr14.log fix-main-log.txt \
  ci-fix-log.txt ship-pr-result.txt \
  combined_output.txt \
  .merge-result.txt \
  .git-status-tmp.txt pytest-out.txt stash-pop.txt \
  git-st.txt commit-check.txt branch-state.txt rebase-state.txt \
  final-status.txt diff-detail.txt diff-stat.txt \
  .ci-investigation-gh.txt .git-commit-msg-tmp.txt \
  hello-wsl.txt scripts/.wsl-sync-test; do
  rm_one "$f"
done

shopt -s nullglob
for f in \
  _fix-main*.log .resolve-*.log \
  tmp-*.txt *-log.txt *-state.txt show-*.txt; do
  rm_one "$f"
done
shopt -u nullglob

if [[ -d home ]] && ! git ls-files --error-unmatch home >/dev/null 2>&1; then
  if [[ -z "$(git ls-files home 2>/dev/null)" ]]; then
    rm -rf home
    echo "removed: home/ (accidental, not tracked)"
    removed=$((removed + 1))
  fi
fi

if [[ "${1:-}" == "--all" ]]; then
  if [[ -d .agent-local ]]; then
    rm -rf .agent-local
    echo "removed: .agent-local/"
    removed=$((removed + 1))
  fi
fi

if [[ "$removed" -eq 0 ]]; then
  echo "no stale agent artifacts at repo root"
else
  echo "cleanup done ($removed item(s))"
fi
