#!/usr/bin/env bash
# Block known bash script dependency cycles (fork storms / WSL freeze).
# Called from check-pr-tooling.sh and ci-check.sh — must stay fast (no network, no ci-check).
# Usage: bash scripts/check-bash-script-cycles.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

errors=0

# Documented cycle (2026-06): ci-check → check-pr-tooling → render-pr-body → pr-ci-checkbox → ci-check
echo "== script cycles: pr-ci-checkbox must not call ci-check =="
if grep -vE '^\s*#' "$ROOT/scripts/pr-ci-checkbox.sh" | grep -qE 'ci-check\.sh'; then
  echo "ERROR: scripts/pr-ci-checkbox.sh invokes ci-check.sh (infinite loop with check-pr-tooling)" >&2
  echo "  Fix: use gh pr checks only; leave checkbox unchecked when no open PR." >&2
  errors=$((errors + 1))
fi

echo "== script cycles: check-pr-tooling must skip pr-ci-checkbox in self-check =="
if ! grep -q 'RENDER_PR_BODY_SKIP_CI_CHECKBOX=1' "$ROOT/scripts/check-pr-tooling.sh"; then
  echo "ERROR: check-pr-tooling.sh must set RENDER_PR_BODY_SKIP_CI_CHECKBOX=1 when calling render-pr-body.sh" >&2
  errors=$((errors + 1))
fi

echo "== script cycles: render-pr-body must honor skip env =="
if ! grep -q 'RENDER_PR_BODY_SKIP_CI_CHECKBOX' "$ROOT/scripts/render-pr-body.sh"; then
  echo "ERROR: render-pr-body.sh missing RENDER_PR_BODY_SKIP_CI_CHECKBOX guard" >&2
  errors=$((errors + 1))
fi

# Optional sanity: warn if this shell already has too many bash children (post-incident signal)
bash_count="$(pgrep -c bash 2>/dev/null || echo 0)"
if [[ "$bash_count" -gt 400 ]]; then
  echo "WARN: pgrep -c bash = ${bash_count} (if scripts hang, run: wsl --shutdown from Windows PowerShell)" >&2
fi

if [[ "$errors" -gt 0 ]]; then
  echo "Script cycle check FAILED ($errors). See docs/agent-git-playbook.md (bash storm)." >&2
  exit 1
fi

echo "Script cycle check passed."
