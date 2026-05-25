# Commit / PR / Issue 例

## 例 0: main にいる変更をブランチへ移して PR

```bash
git checkout -b feat/wbs-2-3-sheets-export   # 未コミット変更はそのまま付いてくる
git add .
git commit -m "feat(spreadsheet): Sheets export 骨組み (WBS 2.3)"
git push -u origin HEAD
gh pr create --base main --title "feat(spreadsheet): add Sheets export skeleton (WBS 2.3)" --body "..."
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

**タイトル**: `feat(spreadsheet): add Sheets export skeleton (WBS 2.3)`

```markdown
## Summary

- Add Sheets export service; portfolio returns count only _(確定アイテムの Sheets 出力。portfolio は Mock)_
- Initial WBS 2.3 implementation _(WBS 2.3 初版)_

## Test plan

- [ ] `bash scripts/ci-check.sh`
- [ ] CI `backend` / `frontend` green
- [ ] portfolio export API returns count only _(件数のみ返すこと)_

## Related

- Issue: Closes #42
- Branch: `feat/wbs-2-3-sheets-export`
- WBS: 2.3 — Google Sheets export
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

**タイトル**: `fix(review): show manual ASIN UI when candidate list is empty`

```markdown
## Summary

- Fall back to manual ASIN form when candidate list is empty _(候補 0 件で手動 ASIN UI)_

## Test plan

- [ ] `bash scripts/ci-check.sh`
- [ ] CI `backend` / `frontend` green
- [ ] Manual ASIN UI appears for jobs with zero candidates _(候補なしジョブで表示)_

## Related

- Issue: Closes #55
- Branch: `fix/review-empty-candidates`
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

**タイトル**: `feat(review): show Gemini candidates on review screen`

```markdown
## Summary

- Show Gemini candidates on the review screen _(レビュー画面に Gemini 候補を表示)_

## Test plan

- [ ] `bash scripts/ci-check.sh`
- [ ] CI `backend` / `frontend` green

## Related

- Issue: Closes #60
- PR: Depends on #61
- PR: Related #61
- Branch: `feat/wbs-2-2c-gemini-matcher-ui`
- WBS: 2.2c — Gemini multimodal matcher
```

---

## 例 4: ドキュメントのみ

```
docs(wbs): Phase 2 タスク 2.2 を完了に更新

実装済みタスクの状態を roadmap と揃える。
```

```markdown
## Summary

- Mark WBS 2.2 tasks as done in roadmap _(roadmap の 2.2 を完了に更新)_

## Test plan

- [ ] Roadmap IDs match implementation _(表の ID・成果物パスが実装と一致)_

## Related

- WBS: 2.2 — candidate matching
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
