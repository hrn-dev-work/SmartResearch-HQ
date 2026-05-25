#!/usr/bin/env bash
# Render PR body: English block (Summary/Commits/Test plan/Related) → --- → Japanese block.
# Usage:
#   bash scripts/render-pr-body.sh manual [branch]
#   bash scripts/render-pr-body.sh auto <branch> [base]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${1:-manual}"
BRANCH="${2:-feat/...}"
BASE="${3:-main}"

CI="$(bash "$ROOT/scripts/pr-ci-checkbox.sh" "$BRANCH" 2>/dev/null || echo " ")"

format_commits() {
  local log
  log="$(git log "origin/${BASE}..HEAD" --format=%s 2>/dev/null || git log "${BASE}..HEAD" --format=%s 2>/dev/null || true)"
  if [[ -z "$log" ]]; then
    echo "* (no commits ahead of ${BASE})"
    return
  fi
  while IFS= read -r subject; do
    [[ -z "$subject" ]] && continue
    if [[ "$subject" =~ ^([^:]+):\ (.+)$ ]]; then
      echo "* \`${BASH_REMATCH[1]}\`: ${BASH_REMATCH[2]}"
    else
      echo "* ${subject}"
    fi
  done <<<"$log"
}

render_manual() {
  cat <<EOF
**Summary**

* What changed

**Commits**

* \`type(scope)\`: short description

**Test plan**

* [${CI}] \`bash scripts/ci-check.sh\` passes
* [${CI}] CI backend / frontend green
* [ ] (Add manual checks if needed)

**Related**

* **Branch:** \`${BRANCH}\`
* **WBS:** x.y

---

**概要 (Summary)**

* 変更内容

**コミット (Commits)**

* \`type(scope)\`: 短い説明

**テスト計画 (Test plan)**

* [${CI}] \`bash scripts/ci-check.sh\` が通る
* [${CI}] CI backend / frontend green
* [ ] （手動確認があれば記述）

**関連 (Related)**

* **ブランチ:** \`${BRANCH}\`
* **WBS:** x.y
EOF
}

render_auto() {
  local commits
  commits="$(format_commits)"

  cat <<EOF
**Summary**

* Auto-created on push to \`${BRANCH}\`. Fill in before merge.

**Commits**

${commits}

**Test plan**

* [${CI}] \`bash scripts/ci-check.sh\` passes
* [${CI}] CI backend / frontend green

**Related**

* **Branch:** \`${BRANCH}\`

---

**概要 (Summary)**

* \`${BRANCH}\` への push 後に自動作成。マージ前に変更内容を追記すること。

**コミット (Commits)**

${commits}

**テスト計画 (Test plan)**

* [${CI}] \`bash scripts/ci-check.sh\` が通る
* [${CI}] CI backend / frontend green

**関連 (Related)**

* **ブランチ:** \`${BRANCH}\`
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
