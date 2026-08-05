#!/usr/bin/env bash
# Enable GitHub Secret Scanning + Push Protection; verify both enabled.
# Usage: bash scripts/enable-github-secret-scanning.sh [owner/repo]
# Exit 0 only when both features report enabled.

set -euo pipefail

if [[ -n "${1:-}" ]]; then
  REPO="$1"
else
  REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)"
fi

if [[ -z "${REPO:-}" ]]; then
  echo "ERROR: pass owner/repo or run inside a gh-linked repo" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh CLI not found" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "ERROR: gh not authenticated (gh auth login)" >&2
  exit 1
fi

echo "Enabling secret scanning + push protection for $REPO ..."

payload='{
  "security_and_analysis": {
    "secret_scanning": { "status": "enabled" },
    "secret_scanning_push_protection": { "status": "enabled" }
  }
}'

if ! gh api "repos/$REPO" -X PATCH --input - <<<"$payload" >/dev/null; then
  echo "ERROR: API enable failed (admin / plan)." >&2
  echo "Manual: https://github.com/$REPO/settings/security_analysis" >&2
  exit 1
fi

ss="$(gh api "repos/$REPO" --jq '.security_and_analysis.secret_scanning.status // "unknown"')"
pp="$(gh api "repos/$REPO" --jq '.security_and_analysis.secret_scanning_push_protection.status // "unknown"')"
echo "secret_scanning=$ss"
echo "secret_scanning_push_protection=$pp"

if [[ "$ss" != "enabled" || "$pp" != "enabled" ]]; then
  echo "ERROR: expected both enabled" >&2
  echo "Manual: https://github.com/$REPO/settings/security_analysis" >&2
  exit 1
fi

echo "OK: Secret Scanning + Push Protection enabled for $REPO"
