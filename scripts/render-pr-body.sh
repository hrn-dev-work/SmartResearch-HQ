#!/usr/bin/env bash
# Render PR body (manual scaffold or auto after push).
# Usage:
#   bash scripts/render-pr-body.sh manual [branch]
#   bash scripts/render-pr-body.sh auto <branch> [base]

set -euo pipefail

MODE="${1:-manual}"
BRANCH="${2:-feat/...}"
BASE="${3:-main}"

render_manual() {
  cat <<EOF
## Summary

- What changed _(変更内容)_

## Test plan

- [ ] \`bash scripts/ci-check.sh\`
- [ ] CI \`backend\` / \`frontend\` green

## Related

<!-- English keywords for GitHub. Delete unused lines. -->
- Branch: \`${BRANCH}\`
- WBS: x.y
- Issue: Closes #
EOF
}

render_auto() {
  local commits
  commits="$(git log "origin/${BASE}..HEAD" --format='- %s' 2>/dev/null || git log "${BASE}..HEAD" --format='- %s' 2>/dev/null || true)"
  if [[ -z "$commits" ]]; then
    commits="- (no commits ahead of ${BASE})"
  fi

  cat <<EOF
## Summary

- Auto-created on push to \`${BRANCH}\` — fill in before merge _(push 後に自動作成。マージ前に追記)_
${commits}

## Test plan

- [ ] \`bash scripts/ci-check.sh\`
- [ ] CI \`backend\` / \`frontend\` green

## Related

- Branch: \`${BRANCH}\`
EOF
}

case "$MODE" in
  manual) render_manual ;;
  auto) render_auto ;;
  *)
    echo "Usage: bash scripts/render-pr-body.sh manual [branch]" >&2
    echo "       bash scripts/render-pr-body.sh auto <branch> [base]" >&2
    exit 1
    ;;
esac
