# Public documentation conventions

Tracked markdown in this repository (README, `docs/*.md`, `frontend/README.md`) follows the same bilingual shape as pull request bodies:

1. **English** — full content for international readers and agents  
2. **`---`** — horizontal rule on its own line (language boundary)  
3. **Japanese** — full mirror with the same heading structure (not a short footer)

**Automated check:** `bash scripts/validate-public-docs.sh` (also runs in `ci-check.sh` and pre-commit when public md is staged).

**Not in scope:** `.github/ISSUE_TEMPLATE/*.md` (YAML front matter uses `---` at file top). UI copy lives in `frontend/src/lib/messages/`, not in these files.

**Cursor rule (local):** `.cursor/rules/docs-editing.mdc` points here; this file is the git-tracked canonical copy.

---

## Checklist when editing public md

| Step | Action |
|------|--------|
| 1 | Update the **English** block first |
| 2 | Add or refresh the **`---`** separator before the Japanese block |
| 3 | Update the **Japanese** block to match section headings and meaning |
| 4 | Run `bash scripts/validate-public-docs.sh` (or `bash scripts/ci-check.sh`) |
| 5 | Use branch prefix `docs/...` when the PR is docs-only |

---

## Common failures (recurrence prevention)

| Symptom | Cause | Fix |
|---------|-------|-----|
| English-only README | No Japanese mirror | Add `# …（日本語）` section after `---` with full parallel sections |
| Japanese bullets only at end of README | Old “footer” pattern | Replace with full JA document after `---` |
| Japanese-only `docs/*.md` | Spec written in JA first | Prepend English block, then `---`, keep existing JA |
| Rule only in `.cursor/` | `.cursor/` is gitignored | Edit **this file** + `docs/agent-git-playbook.md` |
| Docs PR on `chore/security-*` branch | Wrong branch reused | `git-start-branch.sh docs/<topic>` for docs-only work |

---

# 公開ドキュメントの規約

git で追跡する Markdown（README、`docs/*.md`、`frontend/README.md`）は PR 本文と同じ **英語 → `---` → 日本語** です。

1. **英語** — 海外向け・エージェント向けの全文  
2. **`---`** — 単独行の水平線（言語の境界）  
3. **日本語** — 見出し構成を揃えた全文（末尾の箇条書きだけにしない）

**自動検証:** `bash scripts/validate-public-docs.sh`（`ci-check.sh` および public md を stage した pre-commit でも実行）。

**対象外:** `.github/ISSUE_TEMPLATE/*.md`（先頭の `---` は YAML front matter）。UI 文言は `frontend/src/lib/messages/`。

**Cursor ルール（ローカル）:** `.cursor/rules/docs-editing.mdc` は本書へのリンク。正本は **このファイル**（git 追跡）。

---

## 編集時チェックリスト

| # | 作業 |
|---|------|
| 1 | **英語**ブロックを先に更新 |
| 2 | 日本語ブロックの直前に **`---`** を置く |
| 3 | **日本語**ブロックを見出しごと英語と整合させる |
| 4 | `bash scripts/validate-public-docs.sh`（または `ci-check.sh`）を実行 |
| 5 | docs のみの PR ならブランチ名 `docs/...` を使う |

---

## よくある失敗（再発防止）

| 症状 | 原因 | 対策 |
|------|------|------|
| README が英語のみ | 日本語ミラーなし | `---` の後に `（日本語）` 見出しで全文を追加 |
| README 末尾だけ日本語 | 旧フッター形式 | `---` 以降を英語と同構成の全文に差し替え |
| `docs/*.md` が日本語のみ | 仕様を JA のみで記述 | 先頭に英語ブロック + `---` + 既存 JA |
| ルールが `.cursor/` のみ | gitignore | **本書** と `agent-git-playbook.md` を更新 |
| docs PR が無関係ブランチ | ブランチ流用 | `git-start-branch.sh docs/<topic>` |
