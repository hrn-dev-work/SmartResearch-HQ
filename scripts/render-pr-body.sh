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

CI="$(bash "$ROOT/scripts/pr-ci-checkbox.sh" "$BRANCH" 2>/dev/null || echo " ")"

format_commits() {
  local branch="${1:-}"
  case "$branch" in
    chore/security-scanning-docs)
      cat <<'EOF'
* `merge main`: sync git-hooks and security docs
* `chore(security)`: add scanning docs and workflow guardrails
EOF
      return
      ;;
  esac

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

format_commits_ja() {
  local branch="$1"
  case "$branch" in
    chore/security-scanning-docs)
      cat <<'EOF'
* `merge main`: git-hooks と security docs を同期
* `chore(security)`: スキャン docs と workflow ガードレールを追加
EOF
      return
      ;;
  esac

  format_commits "$branch"
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
    chore/security-scanning-docs)
      cat <<'EOF'
* Add `docs/security-scanning.md` canonical guide (defense in depth, CodeQL guardrails, PR merge checklist)
* Add `scripts/validate-security-workflows.sh` to guard CodeQL/CI security workflow config
* Normalize file modes on docs and validator script (100755 → 100644)
EOF
      return
      ;;
    docs/guardrails-engineering-principles)
      cat <<'EOF'
* Add CONTEXT security guardrails, OWASP/IPA §5, and four engineering principles
* Add ADR 0006/0007 and agent docs (security, engineering-principles, rollout tasks)
* Link security-scanning.md to agents/security; git-tracked staging bundle for WSL sync
EOF
      return
      ;;
    chore/pr-tooling-guardrails)
      cat <<'EOF'
* Add bilingual `docs/git-hooks.md` (pre-commit / post-push install guide)
* Extend `check-pr-tooling.sh` to require validate-pr-body, crosslink script, sync/update PR body helpers
* Ship `update-pr-body-from-file.sh` for REST-safe PR body updates
EOF
      return
      ;;
    chore/wsl-cursor-workspace-settings)
      cat <<'EOF'
* WSL-first Cursor workspace settings (`git.path`, terminal profile, file watcher polling)
* Add `verify-wsl-workspace.sh` and document UNC vs WSL desync in agent-shell-fix
* Fix `check-pr-tooling.sh` false positive on body=@ in echo/comment lines
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
    docs/guardrails-engineering-principles)
      cat <<'EOF'
* CONTEXT にセキュリティ規約・OWASP/IPA §5・4 原則を追加
* ADR 0006/0007 と agent docs（security / engineering-principles / rollout）を追加
* security-scanning から agents/security へリンク。WSL 同期用 staging バンドル
EOF
      return
      ;;
    chore/pr-tooling-guardrails)
      cat <<'EOF'
* 二言語 `docs/git-hooks.md`（pre-commit / post-push 導入ガイド）を追加
* `check-pr-tooling.sh` を拡張（validate-pr-body / crosslink / sync / update PR body）
* REST 安全な `update-pr-body-from-file.sh` を同梱
EOF
      return
      ;;
    chore/wsl-cursor-workspace-settings)
      cat <<'EOF'
* Cursor を WSL 優先設定（git.path、ターミナル、file watcher polling）
* `verify-wsl-workspace.sh` と agent-shell-fix に UNC/WSL 不一致の説明を追加
* `check-pr-tooling.sh` の body=@ echo 誤検知を修正
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
    chore/security-scanning-docs)
      cat <<'EOF'
* セキュリティスキャン正本 `docs/security-scanning.md` を追加（多層防御・CodeQL 再発防止・PR マージ前チェック）
* CodeQL / CI 設定を検証する `scripts/validate-security-workflows.sh` を追加
* ドキュメントと検証スクリプトのファイルモードを正規化（100755 → 100644）
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

  echo "* （マージ前に日本語 Summary を追記）"
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
  local commits commits_ja en_summary ja_summary
  commits="$(format_commits "$BRANCH")"
  commits_ja="$(format_commits_ja "$BRANCH")"
  en_summary="$(infer_en_summary "$BRANCH")"
  ja_summary="$(infer_ja_summary "$BRANCH")"

  cat <<EOF
**Summary**

${en_summary}

**Commits**

${commits}

**Test plan**

* [${CI}] \`bash scripts/ci-check.sh\` passes
* [${CI}] CI backend / frontend green
* [ ] Live demo loads and research flow works (if deploy changed)

**Related**

* **Branch:** \`${BRANCH}\`
* **Demo:** https://smart-research-hq.vercel.app

---

**概要 (Summary)**

${ja_summary}

**コミット (Commits)**

${commits_ja}

**テスト計画 (Test plan)**

* [${CI}] \`bash scripts/ci-check.sh\` が通る
* [${CI}] CI backend / frontend green
* [ ] デモ URL でリサーチフローが動作（デプロイ変更時）

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
