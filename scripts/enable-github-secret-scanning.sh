#!/usr/bin/env bash
# Enable GitHub Secret Scanning + Push Protection (repo admin required).
# Usage: bash scripts/enable-github-secret-scanning.sh [owner/repo]
#
# Public repos: usually free. Private repos may require GitHub Advanced Security.
# Manual fallback: https://github.com/<owner>/<repo>/settings/security_analysis

set -euo pipefail

REPO="${1:-hrn-dev-work/SmartResearch-HQ}"

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh CLI not found. Install: https://cli.github.com/" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "ERROR: gh not authenticated. Run: gh auth login" >&2
  exit 1
fi

echo "Enabling secret scanning + push protection for $REPO ..."

payload='{
  "security_and_analysis": {
    "secret_scanning": { "status": "enabled" },
    "secret_scanning_push_protection": { "status": "enabled" }
  }
}'

if gh api "repos/$REPO" -X PATCH --input - <<<"$payload"; then
  echo "OK: API request succeeded."
else
  echo "WARN: could not enable via API (private repo / Advanced Security / admin role)." >&2
  echo "Enable manually: https://github.com/$REPO/settings/security_analysis" >&2
  echo "  - Secret scanning" >&2
  echo "  - Push protection" >&2
  exit 1
fi

gh api "repos/$REPO" --jq '.security_and_analysis | {secret_scanning, secret_scanning_push_protection}'
