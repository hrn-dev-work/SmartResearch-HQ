#!/usr/bin/env bash
# Agent/script tee logs live under .agent-local/ (gitignored), never repo root.
# Usage: source this file, then:
#   LOG="$(agent_local_log_path my-script.log)"
#   : >"$LOG"
#   exec > >(tee -a "$LOG") 2>&1

agent_local_log_dir() {
  local root
  root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  local dir="$root/.agent-local"
  mkdir -p "$dir"
  printf '%s\n' "$dir"
}

agent_local_log_path() {
  local name="${1:?log file name required}"
  printf '%s/%s\n' "$(agent_local_log_dir)" "$name"
}
