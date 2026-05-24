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

- (Describe what changed in English)

## 概要

- （変更内容を日本語で記述）

## Test plan

- [ ] \`bash scripts/ci-check.sh\` passes
- [ ] CI \`backend\` / \`frontend\` green
- [ ] (Add manual checks if needed)

## テスト手順

- [ ] \`bash scripts/ci-check.sh\` が通る
- [ ] CI \`backend\` / \`frontend\` が green
- [ ] （手動確認があれば記述）

## Related

<!-- Keep English keywords for GitHub. Remove unused lines. -->
- Issue: Closes #
- Issue: Refs #
- PR: Depends on #
- PR: Related #
- Branch: \`${BRANCH}\`
- WBS: x.y — task name

## 関連

- イシュー: Closes #（上記 Related と同じ番号）
- PR: Depends on #（上記 Related と同じ番号）
- ブランチ: \`${BRANCH}\`
- WBS: x.y — タスク名
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

- Auto-created on push to \`${BRANCH}\`. Add summary before merge.

## 概要

- \`${BRANCH}\` への push 後に自動作成。マージ前に変更内容を追記すること。

## Commits

${commits}

## コミット

${commits}

## Test plan

- [ ] \`bash scripts/ci-check.sh\` passes
- [ ] CI \`backend\` / \`frontend\` green

## テスト手順

- [ ] \`bash scripts/ci-check.sh\` が通る
- [ ] CI \`backend\` / \`frontend\` が green

## Related

- Branch: \`${BRANCH}\`

## 関連

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
