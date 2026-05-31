#!/usr/bin/env bash
# Post-commit / post-push automation: roadmap sync, PR checkbox sync.
# Usage: bash scripts/post-workflow.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

bash "$ROOT/scripts/sync-wbs-roadmap.sh" --quiet || true

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  BRANCH="$(git branch --show-current)"
  if [[ "$BRANCH" != "main" && "$BRANCH" != "master" ]]; then
    bash "$ROOT/scripts/sync-pr-body.sh" "$BRANCH" 2>/dev/null || true
  fi
fi
