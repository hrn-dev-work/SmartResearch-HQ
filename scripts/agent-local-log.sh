#!/usr/bin/env bash
# Agent/script logs live under .agent-local/ (gitignored), never repo root.
#
# Usage:
#   # shellcheck source=agent-local-log.sh
#   source "$(dirname "$0")/agent-local-log.sh"
#   agent_local_tee_begin my-script.log
#
# agent-run.sh uses agent_latest_log_path / agent_latest_exit_path (truncated each run).

agent_local_repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

agent_local_log_dir() {
  local dir
  dir="$(agent_local_repo_root)/.agent-local"
  mkdir -p "$dir"
  printf '%s\n' "$dir"
}

agent_local_log_path() {
  local name="${1:?log file name required}"
  name="$(basename "$name")"
  printf '%s/%s\n' "$(agent_local_log_dir)" "$name"
}

agent_latest_log_path() {
  agent_local_log_path "latest.log"
}

agent_latest_exit_path() {
  agent_local_log_path "latest.exit"
}

# Truncate and tee stdout/stderr to .agent-local/<name> (never repo root).
agent_local_tee_begin() {
  local log
  log="$(agent_local_log_path "${1:?log file name required}")"
  : >"$log"
  exec > >(tee -a "$log") 2>&1
}

# Remove legacy agent tee logs accidentally written at repo root.
agent_clean_root_junk() {
  local root
  root="$(agent_local_repo_root)"
  rm -f \
    "$root/agent-cmd-output.txt" \
    "$root/agent-cmd-exit.txt" \
    "$root/agent-vercel-deploy.log" \
    "$root/agent-ui-check.log" \
    "$root/agent-pr-merge.log" \
    "$root/merge-result.txt" \
    "$root/ship-split-result.log" \
    "$root/.agent-pr-result.txt" \
    "$root"/.agent-*.log \
    "$root"/.agent-*.txt \
    "$root"/.agent-*.sh \
    "$root"/.ship-*.log \
    2>/dev/null || true
}
