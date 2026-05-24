#!/usr/bin/env bash
set -euo pipefail
cd /home/haruna/workspace/SmartResearch-HQ

python3 <<'PY'
import json
from pathlib import Path

body2 = """## Summary

**Merge order: Step 2 of 3** (after phase1 baseline on `main`)

- WBS 2.3: Google Sheets export for production
- WBS 3.4: job progress polling on review screen
- CI / agent workflow scaffolding
- Ruff format pass

## 概要

**マージ順: 3 段階の 2/3**（`main` 上の phase1 ベースライン後）

- WBS 2.3: 本番向け Google Sheets エクスポート
- WBS 3.4: レビュー画面のジョブ進捗ポーリング
- CI / エージェントワークフローの骨組み
- Ruff フォーマット適用

## Commits

- style(backend): apply ruff format
- feat(frontend): add job progress polling on review screen (WBS 3.4)
- chore: add Cursor rules, hooks, CI, and agent workflow
- fix(api): return SPREADSHEET_CONFIG on Sheets export misconfiguration
- feat(spreadsheet): Google Sheets export for production (WBS 2.3)

## コミット

- style(backend): apply ruff format
- feat(frontend): add job progress polling on review screen (WBS 3.4)
- chore: add Cursor rules, hooks, CI, and agent workflow
- fix(api): return SPREADSHEET_CONFIG on Sheets export misconfiguration
- feat(spreadsheet): Google Sheets export for production (WBS 2.3)

## Test plan

- [ ] `bash scripts/ci-check.sh` passes
- [ ] CI `backend` / `frontend` green

## テスト手順

- [ ] `bash scripts/ci-check.sh` が通る
- [ ] CI `backend` / `frontend` が green

## Merge sequence

1. **Phase 1** — already on `main` (`c251cfc`, same as `phase1` branch)
2. **This PR (#2)** — `phase2` → `main`
3. **PR #1** — `phase3` → `main` (after this PR merges; rebase base to `main` first)

## マージ順

1. **Phase 1** — 済み（`main` に `c251cfc`、`phase1` ブランチと同一コミット）
2. **本 PR (#2)** — `phase2` → `main`
3. **PR #1** — `phase3` → `main`（本 PR マージ後。base を `main` に rebase してから）

## Related

- Branch: `phase2`
- WBS: 2.3, 3.4
- Blocks: #1

## 関連

- ブランチ: `phase2`
- WBS: 2.3, 3.4
- ブロック: #1
"""

body1 = """## Summary

**Merge order: Step 3 of 3** (after PR #2 merges)

Incremental Phase 3 work on top of `phase2`:

- WBS 3.5: Redis health check on `/health` (production)
- WBS 3.6: manual ASIN input on review screen (portfolio mock)
- Dev environment: EditorConfig, VS Code/Cursor settings, README
- Auto PR on push (GitHub Actions + hooks)

## 概要

**マージ順: 3 段階の 3/3**（PR #2 マージ後）

`phase2` 上の Phase 3 追加分:

- WBS 3.5: 本番 `/health` の Redis ヘルスチェック
- WBS 3.6: レビュー画面の手動 ASIN 入力（portfolio mock）
- 開発環境: EditorConfig、VS Code/Cursor 設定、README
- push 時の自動 PR（GitHub Actions + hooks）

## Commits (vs phase2)

- feat(backend): Redis health check for production (WBS 3.5)
- feat(review): manual ASIN input on review screen (WBS 3.6)
- chore: add editor config, dev environment docs, and ruff fixes
- chore: auto-create PR on push

## コミット（phase2 比）

- feat(backend): Redis health check for production (WBS 3.5)
- feat(review): manual ASIN input on review screen (WBS 3.6)
- chore: add editor config, dev environment docs, and ruff fixes
- chore: auto-create PR on push

## Test plan

- [ ] `bash scripts/ci-check.sh` passes
- [ ] CI `backend` / `frontend` green
- [ ] Portfolio: manual ASIN on review item with no candidates

## テスト手順

- [ ] `bash scripts/ci-check.sh` が通る
- [ ] CI `backend` / `frontend` が green
- [ ] portfolio: 候補なしアイテムで手動 ASIN 入力

## Merge sequence

1. **Phase 1** — already on `main`
2. **PR #2** — merge `phase2` → `main` first
3. **This PR (#1)** — then merge `phase3` → `main` (change base to `main` after #2)

## マージ順

1. **Phase 1** — 済み（`main`）
2. **PR #2** — 先に `phase2` → `main` をマージ
3. **本 PR (#1)** — その後 `phase3` → `main`（#2 後に base を `main` へ）

## Related

- Branch: `phase3`
- Base: `phase2` (stacked review; final target is `main`)
- Depends on: #2
- WBS: 3.5, 3.6

## 関連

- ブランチ: `phase3`
- ベース: `phase2`（積み上げレビュー。最終マージ先は `main`）
- 依存: #2
- WBS: 3.5, 3.6
"""

body3 = """## Summary

- Unify PR bodies on English-first bilingual template (GitHub template, auto PR, manual PR, commit-pr-style)
- Add `render-pr-body.sh` for manual/auto PR bodies; drop `gh pr create --fill`
- Each section: English first, Japanese below (`## 概要`, `## テスト手順`, `## 関連`)

## 概要

- PR 本文を英語先の英日併記テンプレに統一（GitHub テンプレ・自動 PR・手動 PR・commit-pr-style）
- `render-pr-body.sh` で手動/自動 PR 本文を生成し、`gh pr create --fill` を廃止
- 各セクションは英語を先に、その下に日本語（`## 概要` / `## テスト手順` / `## 関連`）

## Test plan

- [ ] `bash scripts/ci-check.sh` passes
- [ ] CI `backend` / `frontend` green
- [ ] `bash scripts/render-pr-body.sh manual feat/example` prints expected scaffold

## テスト手順

- [ ] `bash scripts/ci-check.sh` が通る
- [ ] CI `backend` / `frontend` green
- [ ] `bash scripts/render-pr-body.sh manual feat/example` が期待どおりの雛形を出力すること

## Related

- Branch: `chore/pr-body-bilingual-template`

## 関連

- ブランチ: `chore/pr-body-bilingual-template`
"""

Path("/tmp/pr2.json").write_text(json.dumps({"body": body2}))
Path("/tmp/pr1.json").write_text(json.dumps({"body": body1}))
Path("/tmp/pr3.json").write_text(
    json.dumps(
        {
            "title": "chore(git): unify PR bodies on English-first bilingual template",
            "body": body3,
        }
    )
)
PY

gh api repos/hrn-dev-work/SmartResearch-HQ/pulls/2 -X PATCH --input /tmp/pr2.json
gh api repos/hrn-dev-work/SmartResearch-HQ/pulls/1 -X PATCH --input /tmp/pr1.json
gh api repos/hrn-dev-work/SmartResearch-HQ/pulls/3 -X PATCH --input /tmp/pr3.json

echo "Updated PR #1, #2, #3 bodies (English first, Japanese below)"
