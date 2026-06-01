#!/usr/bin/env bash
# Render PR body: English block → --- → Japanese block.
# Usage:
#   bash scripts/render-pr-body.sh manual [branch]
#   bash scripts/render-pr-body.sh auto <branch> [base]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
MODE="${1:-manual}"
BRANCH="${2:-feat/...}"
BASE="${3:-main}"

# Self-check (check-pr-tooling) must not call pr-ci-checkbox → ci-check → check-pr-tooling loop.
if [[ "${RENDER_PR_BODY_SKIP_CI_CHECKBOX:-}" == 1 ]]; then
  CI=" "
else
  CI="$(bash "$ROOT/scripts/pr-ci-checkbox.sh" "$BRANCH" 2>/dev/null || echo " ")"
fi

demo_test_plan_en() {
  local mark
  mark="$(bash "$ROOT/scripts/pr-deploy-demo-checkbox.sh" "$BRANCH" "$BASE" 2>/dev/null || echo "N/A")"
  if [[ "$mark" == "N/A" ]]; then
    echo '* [N/A] Live demo / research flow — skipped (no deploy changes in this PR)'
  else
    echo '* [ ] Live demo loads and research flow works — verify https://smart-research-hq.vercel.app'
  fi
}

demo_test_plan_ja() {
  local mark
  mark="$(bash "$ROOT/scripts/pr-deploy-demo-checkbox.sh" "$BRANCH" "$BASE" 2>/dev/null || echo "N/A")"
  if [[ "$mark" == "N/A" ]]; then
    echo '* [N/A] デモ URL リサーチフロー — 対象外（本 PR はデプロイ変更なし）'
  else
    echo '* [ ] デモ URL でリサーチフローが動作すること（デプロイ変更あり）'
  fi
}

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

subject_to_bullet() {
  local subject="$1"
  if [[ "$subject" == *": "* ]]; then
    echo "* ${subject#*: }"
  else
    echo "* ${subject}"
  fi
}

infer_en_summary() {
  local branch="$1"
  case "$branch" in
    docs/portfolio-deploy-live)
      cat <<'EOF'
* Publish live Demo App URL in README (`https://smart-research-hq.vercel.app`)
* Add deployment troubleshooting doc (Vercel 404 cache, Deployment Protection, CORS)
* Add agent-run, portfolio-vercel-deploy, and agent-push scripts for one-command deploy ops
* Merge `main`: keep i18n frontend from #15; unify agent-push presets
EOF
      return
      ;;
    docs/frontend-structure-viz)
      cat <<'EOF'
* Add frontend structure guide (overview, benefits, usage) and Mermaid maps (routes, layers, imports, i18n)
* Cross-link from architecture.md §5 directory tree (same PR — use check-staged-docs-crosslinks.sh)
EOF
      return
      ;;
    chore/docs-crosslink-guardrails)
      cat <<'EOF'
* Restore `validate-pr-body.sh` and add `check-staged-docs-crosslinks.sh` (WARN after `git-add-safe.sh`)
* Extend `check-pr-tooling.sh` self-check; document docs bundle checklist in agent-git-playbook
EOF
      return
      ;;
    fix/pr-ci-checkbox-cycle)
      cat <<'EOF'
* Break ci-check ↔ check-pr-tooling ↔ render-pr-body ↔ pr-ci-checkbox infinite loop
* Remove local `ci-check.sh` fallback from `pr-ci-checkbox.sh`; skip checkbox in tooling self-check
* Document bash-storm incident in agent-git-playbook
EOF
      return
      ;;
    feat/production-local-setup)
      cat <<'EOF'
* Add production local setup script and documentation
* Wire frontend JA/EN i18n, locale middleware, and UI layout fixes
* Add dev viewport check and stop-next-dev scripts for WSL
EOF
      return
      ;;
    chore/gitignore-local-agent-tooling)
      cat <<'EOF'
* Gitignore local agent debug output and one-off merge scripts
* Add bilingual agent-git-playbook and PR body sync tooling (gh-pr-branch, sync-pr-body)
* Merge main: keep i18n UI, deploy guide, and portfolio mock API parity
EOF
      return
      ;;
  esac

  local log
  log="$(git log "origin/${BASE}..HEAD" --no-merges --format=%s 2>/dev/null || git log "${BASE}..HEAD" --no-merges --format=%s 2>/dev/null || true)"
  if [[ -z "$log" ]]; then
    echo "* (edit Summary before merge)"
    return
  fi
  while IFS= read -r subject; do
    [[ -z "$subject" ]] && continue
    subject_to_bullet "$subject"
  done <<<"$log"
}

infer_ja_summary() {
  local branch="$1"
  case "$branch" in
    docs/portfolio-deploy-live)
      cat <<'EOF'
* README に本番デモ URL（`https://smart-research-hq.vercel.app`）を掲載
* デプロイ障害切り分けドキュメントを追加（Vercel 404・Deployment Protection・CORS）
* agent-run / portfolio-vercel-deploy / agent-push スクリプトを追加
* main マージ: #15 の i18n UI を維持、agent-push の preset を統合
EOF
      return
      ;;
    docs/frontend-structure-viz)
      cat <<'EOF'
* フロント構造ガイド（概要・利点・使い方）と Mermaid 図（ルート・レイヤー・import・i18n）を追加
* architecture.md §5 から相互リンク（同一 PR — `check-staged-docs-crosslinks.sh` で確認）
EOF
      return
      ;;
    chore/docs-crosslink-guardrails)
      cat <<'EOF'
* `validate-pr-body.sh` を復旧し `check-staged-docs-crosslinks.sh` を追加（`git-add-safe.sh` 後に WARN）
* `check-pr-tooling.sh` の自己検査を拡張。agent-git-playbook に docs 束ねチェックリストを追記
EOF
      return
      ;;
    fix/pr-ci-checkbox-cycle)
      cat <<'EOF'
* ci-check と pr-ci-checkbox の循環参照を断ち切り（bash 大量起動の原因）
* `pr-ci-checkbox` からローカル `ci-check` 呼び出しを削除。tooling は CI チェックボックスをスキップ
* agent-git-playbook に bash storm インシデントを追記
EOF
      return
      ;;
    feat/production-local-setup)
      cat <<'EOF'
* 本番ローカル起動スクリプトとドキュメントを追加
* フロント JA/EN 多言語・middleware・UI レイアウト修正
* WSL 向け dev 画面幅チェック・stop-next-dev スクリプトを追加
EOF
      return
      ;;
    chore/gitignore-local-agent-tooling)
      cat <<'EOF'
* エージェント用デバッグ出力・一回限り merge スクリプトを gitignore
* 二言語 agent-git-playbook と PR 本文同期（sync-pr-body / gh-pr-branch）を追加
* main マージ: i18n UI・デプロイ手順・portfolio Mock API 整合を維持
EOF
      return
      ;;
  esac

  local ja_lines=""
  while IFS= read -r block; do
    [[ -z "$block" ]] && continue
    ja_lines+=$'* '"${block}"$'\n'
  done < <(
    git log "origin/${BASE}..HEAD" --no-merges --format=%B 2>/dev/null |
      awk '/^---$/{p=1;next} p && /^[a-zA-Z(]/{p=0} p && NF{sub(/^[ \t]+/,""); print}'
  )

  if [[ -n "$ja_lines" ]]; then
    printf '%s' "$ja_lines" | sed '/^$/d' | while IFS= read -r line; do
      echo "* ${line}"
    done
    return
  fi

  infer_en_summary "$branch" | while IFS= read -r line; do
    echo "$line"
  done
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
  local commits en_summary ja_summary demo_en demo_ja
  commits="$(format_commits)"
  en_summary="$(infer_en_summary "$BRANCH")"
  ja_summary="$(infer_ja_summary "$BRANCH")"
  demo_en="$(demo_test_plan_en)"
  demo_ja="$(demo_test_plan_ja)"

  cat <<EOF
**Summary**

${en_summary}

**Commits**

${commits}

**Test plan**

* [${CI}] \`bash scripts/ci-check.sh\` passes
* [${CI}] CI backend / frontend green
${demo_en}

**Related**

* **Branch:** \`${BRANCH}\`
* **Demo:** https://smart-research-hq.vercel.app

---

**概要 (Summary)**

${ja_summary}

**コミット (Commits)**

${commits}

**テスト計画 (Test plan)**

* [${CI}] \`bash scripts/ci-check.sh\` が通る
* [${CI}] CI backend / frontend green
${demo_ja}

**関連 (Related)**

* **ブランチ:** \`${BRANCH}\`
* **デモ:** https://smart-research-hq.vercel.app
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
