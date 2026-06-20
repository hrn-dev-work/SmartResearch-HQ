#!/usr/bin/env bash
# Ship PR1 (docs) then PR2 (tooling) with CI-gated squash merge.
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck source=agent-local-log.sh
source "$(dirname "$0")/agent-local-log.sh"

LOG="$(agent_local_log_path ship-two-guardrails-prs.log)"
: >"$LOG"
exec > >(tee -a "$LOG") 2>&1

echo "=== ship-two-guardrails-prs $(date -Iseconds) ==="
bash scripts/ship-guardrails-pr1.sh
bash scripts/ship-guardrails-pr2.sh
echo "=== both PRs merged ==="
