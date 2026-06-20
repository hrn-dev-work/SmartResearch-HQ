#!/usr/bin/env bash
# UI viewport + JA/EN check. Requires dev server with current i18n code.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT/frontend"
BASE_URL="${BASE_URL:-http://127.0.0.1:3000}"

# shellcheck source=../../scripts/agent-local-log.sh
source "$ROOT/scripts/agent-local-log.sh"

if command -v lsof >/dev/null 2>&1; then
  old_pid="$(lsof -t -i:3000 2>/dev/null | head -1 || true)"
  if [[ -n "$old_pid" ]]; then
    echo "NOTE: port 3000 in use (PID ${old_pid})."
    echo "      If JA shows as English, restart dev: kill ${old_pid} && npm run dev -- --hostname 127.0.0.1 --port 3000"
  fi
fi

if ! curl -sf -o /dev/null "$BASE_URL"; then
  echo "Starting dev server on ${BASE_URL}..."
  npm run dev -- --hostname 127.0.0.1 --port 3000 >/tmp/next-dev.log 2>&1 &
  for _ in $(seq 1 30); do
    curl -sf -o /dev/null "$BASE_URL" && break
    sleep 2
  done
fi

UI_LOG="$(agent_local_log_path ui-viewport-check.log)"

rm -rf .ui-check
node scripts/ui-viewport-check.mjs "$BASE_URL"
exit_code=$?

{
  echo "EXIT=${exit_code}"
  cat .ui-check/report.json
  ls -la .ui-check/
} >"$UI_LOG"

exit "$exit_code"
