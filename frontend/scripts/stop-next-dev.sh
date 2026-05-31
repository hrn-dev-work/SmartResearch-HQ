#!/usr/bin/env bash
# Stop Next.js dev server(s) on port 3000 (WSL: lsof often misses node; use ss/fuser too).
set -euo pipefail
cd "$(dirname "$0")/.."

PORT="${PORT:-3000}"
pids=""

if command -v lsof >/dev/null 2>&1; then
  pids="$(lsof -t -i:"${PORT}" 2>/dev/null || true)"
fi

if [[ -z "$pids" ]] && command -v fuser >/dev/null 2>&1; then
  pids="$(fuser "${PORT}"/tcp 2>/dev/null | tr -s ' ' '\n' | sort -u || true)"
fi

if [[ -z "$pids" ]] && command -v ss >/dev/null 2>&1; then
  while read -r line; do
    [[ "$line" =~ pid=([0-9]+) ]] && pids="${pids} ${BASH_REMATCH[1]}"
  done < <(ss -tlnp 2>/dev/null | grep ":${PORT}" || true)
fi

# Parent shells / node wrappers for next dev
if command -v pgrep >/dev/null 2>&1; then
  while read -r pid; do
    pids="${pids} ${pid}"
  done < <(pgrep -f "next dev.*--port ${PORT}" 2>/dev/null || true)
fi

pids="$(echo "$pids" | tr ' ' '\n' | sort -u | grep -E '^[0-9]+$' || true)"

if [[ -z "$pids" ]]; then
  echo "No process found on port ${PORT}."
else
  echo "Stopping PID(s) on :${PORT}:${pids}"
  # shellcheck disable=SC2086
  kill $pids 2>/dev/null || true
  sleep 2
  still=""
  if command -v ss >/dev/null 2>&1; then
    still="$(ss -tlnp 2>/dev/null | grep ":${PORT}" || true)"
  fi
  if [[ -n "$still" ]] && command -v fuser >/dev/null 2>&1; then
    echo "Port still busy; force kill..."
    fuser -k "${PORT}"/tcp 2>/dev/null || true
    sleep 1
  fi
fi

rm -f .next/dev/lock 2>/dev/null || true

if command -v ss >/dev/null 2>&1 && ss -tlnp 2>/dev/null | grep -q ":${PORT}"; then
  echo "WARN: port ${PORT} may still be in use. Check: ss -tlnp | grep :${PORT}"
  exit 1
fi

echo "Port ${PORT} is free."
echo "Start: npm run dev -- --hostname 127.0.0.1 --port ${PORT}"
