#!/usr/bin/env bash
# Sync docs/wbs-roadmap.md (+ README phase checkboxes) from repo artifacts.
# Usage: bash scripts/sync-wbs-roadmap.sh [--stage]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

STAGE=false
for arg in "$@"; do
  if [[ "$arg" == "--stage" ]]; then
    STAGE=true
  fi
done

python3 "$ROOT/scripts/sync-wbs-roadmap.py"

if [[ "$STAGE" == true ]]; then
  git add docs/wbs-roadmap.md README.md 2>/dev/null || true
fi
