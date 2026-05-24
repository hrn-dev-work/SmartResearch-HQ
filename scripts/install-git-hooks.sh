#!/usr/bin/env bash
# Point this repo at tracked hooks in .githooks/ (post-push -> ensure-pr).
# Usage: bash scripts/install-git-hooks.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

chmod +x .githooks/post-push scripts/ensure-pr.sh scripts/git-push-pr.sh

git config core.hooksPath .githooks

echo "Git hooks installed (core.hooksPath=.githooks)"
echo "  post-push -> scripts/ensure-pr.sh"
echo "Optional: use bash scripts/git-push-pr.sh instead of git push"
