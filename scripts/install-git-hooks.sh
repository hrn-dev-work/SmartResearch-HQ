#!/usr/bin/env bash
# Point this repo at tracked hooks in .githooks/ (pre-commit + post-push).
# Usage: bash scripts/install-git-hooks.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

chmod +x .githooks/pre-commit .githooks/post-push
chmod +x scripts/pre-commit-secret-check.sh scripts/secret-audit.sh scripts/enable-github-secret-scanning.sh 2>/dev/null || true
chmod +x scripts/ensure-pr.sh scripts/post-workflow.sh scripts/sync-wbs-roadmap.sh
chmod +x scripts/sync-pr-checkboxes.sh scripts/sync-pr-body.sh scripts/pr-ci-checkbox.sh scripts/render-pr-body.sh
chmod +x scripts/render-pr-title.sh scripts/render-commit-msg.sh 2>/dev/null || true
chmod +x scripts/git-ship.sh scripts/git-start-branch.sh 2>/dev/null || true
chmod +x scripts/validate-public-docs.sh scripts/check-staged-branch-scope.sh scripts/check-pr-tooling.sh 2>/dev/null || true
chmod +x scripts/git-add-safe.sh scripts/git-merge-main-safe.sh scripts/git-pr-complete.sh 2>/dev/null || true
chmod +x scripts/gh-pr-branch.sh 2>/dev/null || true

git config core.hooksPath .githooks
# Ignore chmod-only noise when Cursor (Windows) and WSL share the same repo via UNC.
git config core.filemode false

echo "Git hooks installed (core.hooksPath=.githooks, core.filemode=false)"
echo "  pre-commit  -> secret check + sync WBS roadmap + README phase checkboxes"
echo "  post-push   -> sync PR checkboxes (existing PR only; use git-ship pr to create)"
echo "Ship: bash scripts/git-ship.sh push | pr"
echo "PR作成まで: bash scripts/git-pr-complete.sh"
