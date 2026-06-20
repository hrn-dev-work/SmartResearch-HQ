#!/usr/bin/env bash
# PR作成まで with agent-run logging (empty Shell output workaround).
# Usage: bash scripts/agent-git-pr-complete.sh [optional commit subject]
#
# From Windows Cursor agent host:
#   wsl.exe -d Ubuntu bash -lc 'cd ~/workspace/SmartResearch-HQ && bash scripts/agent-git-pr-complete.sh'
#
# After run, Read .agent-local/latest.log for PR URL and full log.

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec bash "$ROOT/scripts/agent-run.sh" -- bash "$ROOT/scripts/git-pr-complete.sh" "$@"
