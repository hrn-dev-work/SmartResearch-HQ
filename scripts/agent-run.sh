#!/usr/bin/env bash
# Run a command with full logging for Cursor agents (empty Shell output workaround).
# Usage: bash scripts/agent-run.sh -- bash scripts/portfolio-vercel-deploy.sh redeploy
#
# After run, read (under .agent-local/, truncated each run):
#   latest.log   — full stdout/stderr
#   latest.exit  — exit code

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=agent-local-log.sh
source "$ROOT/scripts/agent-local-log.sh"

agent_clean_root_junk
OUT="$(agent_latest_log_path)"
EXIT="$(agent_latest_exit_path)"

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
