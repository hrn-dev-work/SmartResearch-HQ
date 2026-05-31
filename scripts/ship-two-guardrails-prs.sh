#!/usr/bin/env bash
# Ship PR1 (docs) then PR2 (tooling) with CI-gated squash merge.
set -euo pipefail
cd "$(dirname "$0")/.."
LOG="${PWD}/.agent-ship-guardrails.log"
exec > >(tee -a "$LOG") 2>&1

echo "=== ship-two-guardrails-prs $(date -Iseconds) ==="
bash scripts/ship-guardrails-pr1.sh
bash scripts/ship-guardrails-pr2.sh
echo "=== both PRs merged ==="
