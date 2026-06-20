#!/usr/bin/env bash
# Remove stale agent / PR debug artifacts (gitignored). Safe to run anytime.
# Prevention: scripts tee to .agent-local/; agent-run.sh truncates agent-cmd-output.txt.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

removed=0
rm_one() {
  local f="$1"
  if [[ -f "$f" ]]; then
    rm -f "$f"
    echo "removed: $f"
    removed=$((removed + 1))
  fi
}

# Whole directory (preferred location for script tee logs)
if [[ -d .agent-local ]]; then
  rm -rf .agent-local
  echo "removed: .agent-local/"
  removed=$((removed + 1))
fi

# Accidental mkdir from bad path (e.g. home/haruna/... instead of ~/)
if [[ -d home ]] && ! git ls-files --error-unmatch home >/dev/null 2>&1; then
  if [[ -z "$(git ls-files home 2>/dev/null)" ]]; then
    rm -rf home
    echo "removed: home/ (accidental, not tracked)"
    removed=$((removed + 1))
  fi
fi

# Legacy repo-root names (pre .agent-local/)
for f in \
  _fix-main.log _fix-main2.log \
  .ship-closeout.log \
  agent-cmd-output.txt agent-cmd-exit.txt \
  agent-ui-check.log agent-vercel-deploy.log agent-pr-merge.log \
  dependabot-pr-log.txt pr-create-log.txt run-log.txt \
  merge-result.txt combined_output.txt \
  .agent-pr-result.txt \
  .pr13-merge-log.txt .pr13-push-log.txt \
  .sync-pr-log.txt \
  push-pr14.log resolve-pr14.log fix-main-log.txt \
  ci-fix-log.txt ship-pr-result.txt \
  scripts/ship-wsl-settings.log; do
  rm_one "$f"
done

shopt -s nullglob
for f in \
  .ship-*.log _fix-main*.log \
  .agent-*.log .agent-*.txt \
  .resolve-*.log \
  *-log.txt *-state.txt \
  tmp-*.txt show-*.txt \
  git-st.txt commit-check.txt branch-state.txt rebase-state.txt \
  final-status.txt diff-detail.txt diff-stat.txt \
  stash-pop.txt pytest-out.txt .git-status-tmp.txt \
  .git-commit-msg-tmp.txt .ci-investigation-gh.txt \
  .merge-result.txt; do
  rm_one "$f"
done
shopt -u nullglob

if [[ "$removed" -eq 0 ]]; then
  echo "no stale agent artifacts"
else
  echo "cleanup done ($removed item(s))"
fi
