#!/usr/bin/env bash
# Apply branch protection: required checks include secret-audit; block force-push.
#
# Usage: bash scripts/apply-branch-protection.sh [owner/repo] [branch]
#
# Env:
#   EXTRA_CHECKS="lint test"  extra required check contexts (whitespace-separated)
#   REQUIRE_REVIEW=1          require 1 approving review (use when ≥2 maintainers)
#
# Review count default is 0 (solo): still gets required_status_checks + enforce_admins.
# Team repos: always set REQUIRE_REVIEW=1.
# Needs: gh (admin), jq.

set -euo pipefail

if [[ -n "${1:-}" ]]; then
  REPO="$1"
else
  REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)"
fi

if [[ -z "${REPO:-}" ]]; then
  echo "ERROR: pass owner/repo or run in a gh-linked repo" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh CLI not found" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq not found (required to build branch protection payload)" >&2
  echo "Install one of:" >&2
  echo "  sudo apt-get install -y jq" >&2
  echo "  # or binary to ~/.local/bin (ensure PATH includes it):" >&2
  echo "  # https://github.com/jqlang/jq/releases  (jq-linux-amd64)" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "ERROR: gh not authenticated" >&2
  exit 1
fi

BRANCH="${2:-}"
if [[ -z "$BRANCH" ]]; then
  BRANCH="$(gh api "repos/$REPO" --jq .default_branch)"
fi

# Contexts: always secret-audit first; EXTRA_CHECKS appended via jq --args (no string JSON concat).
ctx_args=(secret-audit)
if [[ -n "${EXTRA_CHECKS:-}" ]]; then
  # shellcheck disable=SC2206
  ctx_args+=( ${EXTRA_CHECKS} )
fi
contexts_json="$(jq -n -c '$ARGS.positional' --args -- "${ctx_args[@]}")"

reviews_count=0
dismiss_stale=false
if [[ "${REQUIRE_REVIEW:-0}" == "1" ]]; then
  reviews_count=1
  dismiss_stale=true
fi

echo "Applying branch protection on $REPO branch=$BRANCH contexts=$contexts_json reviews=$reviews_count"

payload="$(
  jq -n \
    --argjson contexts "$contexts_json" \
    --argjson reviews "$reviews_count" \
    --argjson dismiss "$dismiss_stale" \
    '{
      required_status_checks: { strict: true, contexts: $contexts },
      enforce_admins: true,
      required_pull_request_reviews: {
        required_approving_review_count: $reviews,
        dismiss_stale_reviews: $dismiss
      },
      restrictions: null,
      allow_force_pushes: false,
      allow_deletions: false,
      required_conversation_resolution: true
    }'
)"

if ! gh api -X PUT "repos/$REPO/branches/$BRANCH/protection" \
  -H "Accept: application/vnd.github+json" \
  --input - <<<"$payload"; then
  echo "ERROR: could not apply protection (admin / plan / unknown check names)." >&2
  echo "Run CI until check \"secret-audit\" exists on $BRANCH, then re-run." >&2
  echo "UI: https://github.com/$REPO/settings/branches" >&2
  exit 1
fi

echo "OK: branch protection applied on $BRANCH"
gh api "repos/$REPO/branches/$BRANCH/protection" --jq '{
  contexts: .required_status_checks.contexts,
  force_push: .allow_force_pushes.enabled,
  enforce_admins: .enforce_admins.enabled,
  reviews: .required_pull_request_reviews.required_approving_review_count
}' 2>/dev/null || true
