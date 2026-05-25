#!/usr/bin/env bash
# Render PR body (manual scaffold or auto after push).
# Each section: English block, ---, Japanese block. CI checkboxes auto-mark when green.
# Usage:
#   bash scripts/render-pr-body.sh manual [branch]
#   bash scripts/render-pr-body.sh auto <branch> [base]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${1:-manual}"
BRANCH="${2:-feat/...}"
BASE="${3:-main}"

CI="$(bash "$ROOT/scripts/pr-ci-checkbox.sh" "$BRANCH" 2>/dev/null || echo " ")"

render_manual() {
  cat <<EOF
## Summary

- What changed

---

- 変更内容

## Test plan

- [${CI}] \`bash scripts/ci-check.sh\` passes
- [${CI}] CI \`backend\` / \`frontend\` green
- [ ] (Add manual checks if needed)

---

- [${CI}] \`bash scripts/ci-check.sh\` が通る
- [${CI}] CI \`backend\` / \`frontend\` green
- [ ] （手動確認があれば記述）

## Related

<!-- English keywords for GitHub. Delete unused lines. -->
- Branch: \`${BRANCH}\`
- WBS: x.y
- Issue: Closes #

---

- ブランチ: \`${BRANCH}\`
- WBS: x.y
- イシュー: Closes #
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

- Auto-created on push to \`${BRANCH}\`. Fill in before merge.

${commits}

---

- \`${BRANCH}\` への push 後に自動作成。マージ前に変更内容を追記すること。

${commits}

## Test plan

- [${CI}] \`bash scripts/ci-check.sh\` passes
- [${CI}] CI \`backend\` / \`frontend\` green

---

- [${CI}] \`bash scripts/ci-check.sh\` が通る
- [${CI}] CI \`backend\` / \`frontend\` green

## Related

- Branch: \`${BRANCH}\`

---

- ブランチ: \`${BRANCH}\`
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
