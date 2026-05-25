#!/usr/bin/env bash
# Point this repo at tracked hooks in .githooks/ (pre-commit + post-push).
# Usage: bash scripts/install-git-hooks.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

chmod +x .githooks/pre-commit .githooks/post-push
chmod +x scripts/ensure-pr.sh scripts/post-workflow.sh scripts/sync-wbs-roadmap.sh
chmod +x scripts/sync-pr-checkboxes.sh scripts/pr-ci-checkbox.sh scripts/render-pr-body.sh
chmod +x scripts/render-pr-title.sh scripts/render-commit-msg.sh 2>/dev/null || true
chmod +x scripts/git-push-pr.sh 2>/dev/null || true

git config core.hooksPath .githooks

echo "Git hooks installed (core.hooksPath=.githooks)"
echo "  pre-commit  -> sync WBS roadmap + README phase checkboxes"
echo "  post-push   -> ensure PR + sync PR checkboxes"
