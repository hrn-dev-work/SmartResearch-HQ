# Commit / PR / Issue 例

## 例 0: main にいる変更をブランチへ移して PR

```bash
git checkout -b feat/wbs-2-3-sheets-export   # 未コミット変更はそのまま付いてくる
git add .
git commit -m "feat(spreadsheet): Sheets export 骨組み (WBS 2.3)"
git push -u origin HEAD
gh pr create --base main --title "..." --body "..."
```

---

## 例 1: WBS タスク — Issue → ブランチ → コミット → PR

### Issue（着手前）

**タイトル**: `[WBS 2.3] Google Sheets 連携`

```markdown
## 背景
確定済みアイテムをスプレッドシートへ出力する（requirements §2.7）。

## やること
- [ ] `backend/app/services/spreadsheet/` に export サービスを追加
- [ ] production 時のみ Sheets API を呼ぶ

## 受入条件
- [ ] portfolio では件数レスポンスのみ
- [ ] `docs/api-specification.md` の export I/O と一致

## Related
- WBS: 2.3 — Google Sheets 連携
- Docs: [`requirements.md`](../docs/requirements.md)
- Blocked by: #18（Alembic マイグレーション完了）
```

### ブランチ

```bash
bash scripts/git-start-branch.sh feat/wbs-2-3-sheets-export
```

`feat/wbs-2-3-sheets-export`

### コミット

```
feat(spreadsheet): Sheets export サービスの骨組みを追加 (WBS 2.3)

production のみ実 API を呼び、portfolio は件数のみ返す。

Refs #42
```

### PR

**タイトル**: `feat(spreadsheet): Sheets export サービスの骨組みを追加 (WBS 2.3)`

```markdown
## Summary

- Add Sheets export service; portfolio returns count only
- Initial WBS 2.3 implementation

## 概要

- 確定アイテムの Sheets 出力サービスを追加（portfolio は Mock レスポンス）
- WBS 2.3 の初版

## Test plan

- [ ] `bash scripts/ci-check.sh` passes
- [ ] CI `backend` / `frontend` green
- [ ] portfolio export API returns count only

## テスト手順

- [ ] `bash scripts/ci-check.sh` が通る
- [ ] CI `backend` / `frontend` green
- [ ] portfolio で export API が件数のみ返すこと

## Related

- Issue: Closes #42
- Branch: `feat/wbs-2-3-sheets-export`
- WBS: 2.3 — Google Sheets export

## 関連

- イシュー: Closes #42
- ブランチ: `feat/wbs-2-3-sheets-export`
- WBS: 2.3 — Google Sheets 連携
```

---

## 例 2: バグ修正 — Issue と PR の相互参照

### Issue

**タイトル**: `fix(review): 候補が空のとき UI が落ちる`

```markdown
## 現象
`MATCHING_PROVIDER=none` で候補 0 件のとき、レビュー画面が白画面になる。

## 期待
§3.3 の手動 ASIN 入力 UI が表示される。

## 再現手順
1. portfolio でジョブ作成
2. 候補 0 件の Mock データでレビュー画面を開く

## 環境
- APP_MODE: portfolio
```

### コミット

```
fix(review): 候補 0 件でも手動 ASIN UI を表示

Fixes #55
```

### PR

```markdown
## Summary

- Fall back to manual ASIN form when candidate list is empty

## 概要

- 候補空配列時に手動 ASIN フォームへフォールバック

## Test plan

- [ ] `bash scripts/ci-check.sh` passes
- [ ] CI `backend` / `frontend` green
- [ ] Manual ASIN UI appears for jobs with zero candidates

## テスト手順

- [ ] `bash scripts/ci-check.sh` が通る
- [ ] CI `backend` / `frontend` green
- [ ] 候補 0 件のジョブで手動入力 UI が出ること

## Related

- Issue: Closes #55
- Branch: `fix/review-empty-candidates`

## 関連

- イシュー: Closes #55
- ブランチ: `fix/review-empty-candidates`
```

---

## 例 3: 分割 PR（Related PR）

**Issue #60**: `[WBS 2.2c] Gemini マルチモーダルマッチャ`

**PR #61**（API 骨組み）:

```markdown
## Related
- Issue: Refs #60
- Branch: `feat/wbs-2-2c-gemini-matcher-api`
- WBS: 2.2c — Gemini マルチモーダル
```

**PR #62**（UI 連携）:

```markdown
## Summary

- Show Gemini candidates on the review screen

## 概要

- レビュー画面から Gemini 候補を表示

## Related

- Issue: Closes #60
- PR: Depends on #61
- PR: Related #61
- Branch: `feat/wbs-2-2c-gemini-matcher-ui`
- WBS: 2.2c — Gemini multimodal matcher

## 関連

- イシュー: Closes #60
- PR: Depends on #61
- PR: Related #61
- ブランチ: `feat/wbs-2-2c-gemini-matcher-ui`
- WBS: 2.2c — Gemini マルチモーダル
```

---

## 例 4: ドキュメントのみ

```
docs(wbs): Phase 2 タスク 2.2 を完了に更新

実装済みタスクの状態を roadmap と揃える。
```

```markdown
## Summary

- Mark WBS 2.2 tasks as done in roadmap

## 概要

- `docs/wbs-roadmap.md` で 2.2 を完了に更新

## Test plan

- [ ] Roadmap IDs and artifact paths match implementation

## テスト手順

- [ ] 表の ID・成果物パスが実装と一致すること

## Related

- WBS: 2.2 — 候補マッチング
- Branch: `docs/wbs-2-2-done`
```

---

## 例 5: 調査 Issue（スパイク）

**タイトル**: `spike(matching): PA-API レート制限の扱い`

```markdown
## 目的
production で PA-API の throttling 時にリトライ方針を決める。

## 調査項目
- [ ] PA-API エラーコード一覧
- [ ] ARQ ワーカーでのリトライ可否

## 成果物
`docs/architecture.md` §4.2 に方針を追記

## Related
- WBS: 2.2
- Issue: Blocks #70
```
