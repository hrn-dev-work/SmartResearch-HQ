#!/usr/bin/env bash
# Probe Cursor agent shell capture (WSL). Writes full log; prints a short summary to stdout.
# Usage: bash scripts/agent-shell-probe.sh
# After run: Read .agent-local/latest.log if stdout is empty.

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=agent-local-log.sh
source "$ROOT/scripts/agent-local-log.sh"

agent_clean_root_junk
OUT="$(agent_latest_log_path)"
EXIT="$(agent_latest_exit_path)"

{
  echo "=== agent-shell-probe $(date -Iseconds) ==="
  echo "pwd: $(pwd)"
  echo "branch: $(git branch --show-current 2>/dev/null || echo '?')"
  echo "HEAD: $(git rev-parse --short HEAD 2>/dev/null || echo '?')"
  echo ""

  echo "--- test A: direct echo ---"
  echo "probe-direct-ok"

  echo "--- test B: git status (no pipe) ---"
  git status --short 2>&1 | head -5 || true
  echo "(git status lines above: $(git status --short 2>/dev/null | wc -l))"

  echo "--- test C: git status piped (often empty in Cursor Shell) ---"
  piped="$(git status --short 2>/dev/null | head -3 || true)"
  if [[ -n "$piped" ]]; then
    echo "pipe-capture-ok"
    echo "$piped"
  else
    echo "pipe-capture-empty (expected on some Windows agent shells — use agent-run.sh)"
  fi

  echo ""
  echo "=== recommendation ==="
  echo "Use: bash scripts/agent-run.sh -- bash scripts/git-pr-complete.sh"
  echo "Then Read: .agent-local/latest.log and .agent-local/latest.exit"
} >"$OUT" 2>&1

echo 0 >"$EXIT"
echo "agent-shell-probe: PASS log=$OUT bytes=$(wc -c <"$OUT" | tr -d ' ')"
