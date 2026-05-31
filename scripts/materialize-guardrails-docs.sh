#!/usr/bin/env bash
# Copy git-tracked staging bundle into canonical doc paths (WSL-safe).
# Usage: bash scripts/materialize-guardrails-docs.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ST="$ROOT/scripts/guardrails-docs-staging"
cd "$ROOT"

if [[ ! -d "$ST" ]]; then
  echo "ERROR: missing $ST" >&2
  exit 1
fi

install -D "$ST/CONTEXT.md" "$ROOT/CONTEXT.md"
install -D "$ST/README.md" "$ROOT/README.md"

for f in README.md domain.md security.md engineering-principles.md security-rollout-tasks.md; do
  install -D "$ST/docs/agents/$f" "$ROOT/docs/agents/$f"
done

install -D "$ST/docs/adr/README.md" "$ROOT/docs/adr/README.md"
install -D "$ST/docs/adr/0006-security-guardrails-public-standards.md" \
  "$ROOT/docs/adr/0006-security-guardrails-public-standards.md"
install -D "$ST/docs/adr/0007-engineering-principles-for-agents.md" \
  "$ROOT/docs/adr/0007-engineering-principles-for-agents.md"
install -D "$ST/docs/security-scanning.md" "$ROOT/docs/security-scanning.md"

echo "Materialized guardrails docs from $ST"
