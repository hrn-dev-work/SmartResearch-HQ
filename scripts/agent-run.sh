#!/usr/bin/env bash
# Run a command with full logging for Cursor agents (empty Shell output workaround).
# Usage: bash scripts/agent-run.sh -- bash scripts/portfolio-vercel-deploy.sh redeploy
#
# After run, read:
#   agent-cmd-output.txt  — full stdout/stderr (truncated each run)
#   agent-cmd-exit.txt    — exit code

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/agent-cmd-output.txt"
EXIT="$ROOT/agent-cmd-exit.txt"

if [[ "${1:-}" != "--" ]]; then
  echo "Usage: bash scripts/agent-run.sh -- <command...>" >&2
  exit 2
fi
shift

if [[ $# -eq 0 ]]; then
  echo "ERROR: no command after --" >&2
  exit 2
fi

CMD_STR="$*"
code=0
{
  echo "=== agent-run $(date -Iseconds) ==="
  echo "cmd: $CMD_STR"
  echo "pwd: $ROOT"
  echo "--- output ---"
  cd "$ROOT"
  set +e
  "$@"
  code=$?
  set -e
  echo "--- end output ---"
  echo "agent-run: exit=$code log=$OUT"
} >"$OUT" 2>&1

echo "$code" >"$EXIT"
echo "agent-run: exit=$code log=$OUT bytes=$(wc -c <"$OUT" | tr -d ' ')"
exit "$code"
