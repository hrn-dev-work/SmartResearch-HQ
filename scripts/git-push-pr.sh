#!/usr/bin/env bash
# Push current branch and open a PR when missing (alias for git-ship pr).
# Usage: bash scripts/git-push-pr.sh [base] [git-push-args...]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="${1:-main}"
shift || true
exec bash "$ROOT/scripts/git-ship.sh" pr "$BASE" "$@"
