#!/usr/bin/env bash
# Fast "PR作成まで" for docs/CONTEXT/ADR/agents-only changes (skips local pytest + next build).
# Full CI still runs on GitHub. Usage: bash scripts/git-pr-docs-only.sh [commit subject]
set -euo pipefail
export GIT_PR_FAST_DOCS=1
exec bash "$(dirname "$0")/git-pr-complete.sh" "$@"
