#!/usr/bin/env bash
# Sync docs/wbs-roadmap.md (+ README phase checkboxes) from repo artifacts.
# Usage: bash scripts/sync-wbs-roadmap.sh [--stage]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

python3 "$ROOT/scripts/sync-wbs-roadmap.py" "$@"

if [[ "${1:-}" == "--stage" ]]; then
  git add docs/wbs-roadmap.md README.md 2>/dev/null || true
fi
