# Commit / PR / Issue 例

## 例 0: main にいる変更をブランチへ移して PR

```bash
git checkout -b feat/wbs-2-3-sheets-export   # 未コミット変更はそのまま付いてくる
git add .
git commit -m "$(cat <<'EOF'
feat(spreadsheet): add Sheets export skeleton (WBS 2.3)

Call real Sheets API in production only; portfolio returns count.

---

production のみ実 API を呼び、portfolio は件数のみ返す。

Refs #42
EOF
)"
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
feat(spreadsheet): add Sheets export skeleton (WBS 2.3)

Call real Sheets API in production only; portfolio returns count.

---

production のみ実 API を呼び、portfolio は件数のみ返す。

Refs #42
```

### PR

**タイトル**: `feat(spreadsheet): add Sheets export skeleton (WBS 2.3)`

```markdown
## Summary

- Add Sheets export service; portfolio returns count only
- Initial WBS 2.3 implementation

---

- 確定アイテムの Sheets 出力サービスを追加（portfolio は Mock）
- WBS 2.3 の初版

## Test plan

- [ ] `bash scripts/ci-check.sh` passes
- [ ] CI `backend` / `frontend` green
- [ ] portfolio export API returns count only

---

- [ ] `bash scripts/ci-check.sh` が通る
- [ ] CI `backend` / `frontend` green
- [ ] portfolio で export API が件数のみ返すこと

## Related

- Issue: Closes #42
- Branch: `feat/wbs-2-3-sheets-export`
- WBS: 2.3 — Google Sheets export

---

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
fix(review): show manual ASIN UI when candidate list is empty

Fall back to manual ASIN form instead of blank screen.

---

候補 0 件でも白画面にせず、手動 ASIN フォームを表示する。

Fixes #55
```

### PR

**タイトル**: `fix(review): show manual ASIN UI when candidate list is empty`

```markdown
## Summary

- Fall back to manual ASIN form when candidate list is empty

---

- 候補 0 件でも白画面にせず、手動 ASIN フォームを表示

## Test plan

- [ ] `bash scripts/ci-check.sh` passes
- [ ] CI `backend` / `frontend` green
- [ ] Manual ASIN UI appears for jobs with zero candidates

---

- [ ] `bash scripts/ci-check.sh` が通る
- [ ] CI `backend` / `frontend` green
- [ ] 候補 0 件のジョブで手動入力 UI が出ること

## Related

- Issue: Closes #55
- Branch: `fix/review-empty-candidates`

---

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
docs(wbs): mark WBS 2.2 tasks done in roadmap

Align roadmap status with implemented Phase 2 work.

---

実装済み Phase 2 に合わせ roadmap の 2.2 を完了に更新。
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

---

## 例 6: main 上の squash コミット（参考）

`7b871a5` / `7945182` のように、マージ後も読みやすい英日 body にする。

```
chore(git): compact bilingual PR template

Unify PR body to 3 sections with inline _(日本語)_; add render-pr-title.sh.

---

PR 本文を 3 セクション＋同行 _(…)_ に統一。タイトル生成スクリプトを追加。
```

```
feat: Phase 2 Sheets export and job polling (WBS 2.3, 3.4)

Production Sheets export, review-screen job polling, CI scaffolding.

---

本番 Sheets エクスポート、レビュー画面の進捗ポーリング、CI 骨組み。
```
