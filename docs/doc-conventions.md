# Public documentation conventions

Public markdown such as `CONTEXT.md`, `docs/*.md`, and `frontend/README.md` follows the same bilingual shape as pull request bodies:

1. **English** — full content for international readers and agents  
2. **`---`** — horizontal rule on its own line (language boundary)  
3. **Japanese** — full mirror with the same heading structure (not a short footer)

**Root README exception:** `README.md` contains the full Japanese version shown by default; `README.en.md` contains the full English version. Put Japanese-first button-style language links immediately below both titles, pointing to `./README.md` and `./README.en.md`. Highlight the current language. Keep topics, public URLs, and skill tables in sync. `README.ja.md` is a compatibility link to the default Japanese README.

**Automated check:** `bash scripts/validate-public-docs.sh` (also runs in `ci-check.sh` and pre-commit when public md is staged).

**Not in scope:** `.github/ISSUE_TEMPLATE/*.md` (YAML front matter uses `---` at file top). UI copy lives in `frontend/src/lib/messages/`, not in these files.

**ADR exception:** `docs/adr/*.md` is **English-only** (no `---` Japanese mirror). Rationale and rejected alternatives live in the ADR; operational detail in `docs/agents/`. Validated by `bash scripts/validate-adrs.sh` (see [docs/adr/README.md](adr/README.md)).

**Cursor rule (local):** `.cursor/rules/docs-editing.mdc` points here; this file is the git-tracked canonical copy.

**Related:** [git-hooks.md](git-hooks.md) — install local pre-commit hooks that run validate-public-docs.sh when public md is staged.

---

## Checklist when editing public md

For the root README pair, update both language files together and preserve the top language links; the separator steps below apply to other public documents.

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
| Root README lacks a Japanese version | Missing language pair | Keep full Japanese `README.md` and English `README.en.md` with reciprocal buttons |
| English-only CONTEXT.md | No Japanese mirror | Add a full JA block after language-boundary `---` |
| Japanese bullets only at end of README | Old “footer” pattern | Use Japanese `README.md` and English `README.en.md` |
| Japanese-only `docs/*.md` | Spec written in JA first | Prepend English block, then `---`, keep existing JA |
| Rule only in `.cursor/` | `.cursor/` is gitignored | Edit **this file** + `docs/agent-git-playbook.md` |
| Docs PR on `chore/security-*` branch | Wrong branch reused | `git-start-branch.sh docs/<topic>` for docs-only work |

---

# 公開ドキュメントの規約

git で追跡する Markdown（ルートの README 2 ファイルを除く。`CONTEXT.md`、`docs/*.md`、`frontend/README.md`）は PR 本文と同じ **英語 → `---` → 日本語** です。

1. **英語** — 海外向け・エージェント向けの全文  
2. **`---`** — 単独行の水平線（言語の境界）  
3. **日本語** — 見出し構成を揃えた全文（末尾の箇条書きだけにしない）

**ルート README の例外:** `README.md` は最初に表示する日本語の全文、`README.en.md` は英語の全文です。両方のタイトル直下に「日本語 / English」の順でボタン風リンクを置き、`./README.md` と `./README.en.md` に移動できるようにします。現在の言語を強調し、扱う話題・公開 URL・スキル表を同じ変更で揃えます。`README.ja.md` は既存リンクを維持するため、日本語の `README.md` への案内とします。

**自動検証:** `bash scripts/validate-public-docs.sh`（`ci-check.sh` および public md を stage した pre-commit でも実行）。

**対象外:** `.github/ISSUE_TEMPLATE/*.md`（先頭の `---` は YAML front matter）。UI 文言は `frontend/src/lib/messages/`。

**ADR の例外:** `docs/adr/*.md` は **英語のみ**（`---` 以降の日本語ミラーなし）。理由と却下案は ADR、運用詳細は `docs/agents/`。検証は `bash scripts/validate-adrs.sh`（[docs/adr/README.md](adr/README.md) 参照）。

**Cursor ルール（ローカル）:** `.cursor/rules/docs-editing.mdc` は本書へのリンク。正本は **このファイル**（git 追跡）。

**関連:** [git-hooks.md](git-hooks.md) — public md を stage した pre-commit で validate-public-docs.sh を実行するローカル設定。

---

## 編集時チェックリスト

ルート README は両言語のファイルを同時に更新し、冒頭の言語リンクを維持します。以下の区切り線に関する手順は、それ以外の公開ドキュメントに適用します。

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
| ルート README に日本語版がない | 言語ペアなし | 日本語の `README.md` と英語の `README.en.md` に全文と相互のボタンを配置 |
| CONTEXT.md が英語のみ | 日本語ミラーなし | 言語境界の `---` の後に全文ミラー |
| README 末尾だけ日本語 | 旧フッター形式 | 日本語の全文を `README.md`、英語の全文を `README.en.md` に配置 |
| `docs/*.md` が日本語のみ | 仕様を JA のみで記述 | 先頭に英語ブロック + `---` + 既存 JA |
| ルールが `.cursor/` のみ | gitignore | **本書** と `agent-git-playbook.md` を更新 |
| docs PR が無関係ブランチ | ブランチ流用 | `git-start-branch.sh docs/<topic>` |
