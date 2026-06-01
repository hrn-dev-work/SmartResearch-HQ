#!/usr/bin/env bash
# Verify agent doc paths exist on the Linux filesystem (WSL). Run from repo root.
# Usage: bash scripts/verify-wsl-workspace.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "== WSL workspace check =="
echo "pwd: $(pwd)"
echo "branch: $(git branch --show-current 2>/dev/null || echo '?')"
echo "HEAD: $(git rev-parse --short HEAD 2>/dev/null || echo '?')"
echo "origin/main: $(git rev-parse --short origin/main 2>/dev/null || echo '(fetch first)')"

required=(
  CONTEXT.md
  docs/agents/README.md
  docs/agents/security.md
  docs/agents/engineering-principles.md
  docs/adr/0006-security-guardrails-public-standards.md
  docs/adr/0007-engineering-principles-for-agents.md
  docs/adr/0008-ai-guardrails-production-readiness.md
  docs/agents/ai-production-readiness.md
)

missing=0
for f in "${required[@]}"; do
  if [[ -f "$f" ]]; then
    echo "OK  $f"
  else
    echo "MISSING  $f"
    missing=$((missing + 1))
  fi
done

if [[ "$missing" -gt 0 ]]; then
  echo ""
  echo "Fix (run in WSL, repo root):"
  echo "  git fetch origin"
  echo "  git checkout main && git pull --ff-only origin main"
  echo ""
  echo "If still missing after pull, Cursor may be on an old branch — compare:"
  echo "  git log -1 --oneline origin/main"
  echo ""
  echo "Open workspace via: Command Palette → WSL: Reopen Folder in WSL"
  echo "  (path should be ~/workspace/SmartResearch-HQ, not only \\\\wsl.localhost\\...)"
  exit 1
fi

echo "All required agent docs visible on this filesystem."
