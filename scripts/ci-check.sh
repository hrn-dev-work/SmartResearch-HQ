#!/usr/bin/env bash
# Local CI mirror (.github/workflows/ci.yml). Usage: bash scripts/ci-check.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
echo "== pr tooling =="
bash "$ROOT/scripts/check-pr-tooling.sh"

echo "== public docs =="
bash "$ROOT/scripts/validate-public-docs.sh"

