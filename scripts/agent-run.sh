#!/usr/bin/env bash
# Run a command with full logging for Cursor agents (empty Shell output workaround).
# Usage: bash scripts/agent-run.sh -- bash scripts/portfolio-vercel-deploy.sh redeploy
#
# After run, read:
#   agent-cmd-output.txt  — full stdout/stderr
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

set +e
(
  cd "$ROOT"
  "$@"
) > >(tee "$OUT") 2>&1
code=$?
set -e

echo "$code" > "$EXIT"
echo "agent-run: exit=$code log=$OUT" | tee -a "$OUT"
exit "$code"
