# テンプレート集（正本）

スキル `commit-pr-style` と `.github/` 配下の GitHub テンプレは **同じ構成** を使う。更新時は両方を揃える。

ラベル定義: [`.github/labels.json`](../.github/labels.json)（GitHub へ反映: `python3 scripts/sync-github-labels.py`）

---

## ラベル

| ラベル | 用途 | テンプレ既定 |
|--------|------|-------------|
| `type: feature` | 機能・WBS タスク | タスク / 機能 |
| `type: bug` | 不具合 | バグ報告 |
| `type: docs` | 仕様・README のみ | （手動。タスク作成後に差し替え） |
| `type: spike` | 調査 | 調査（スパイク） |
| `type: chore` | 依存・CI・設定 | メンテ（Chore） |
| `status: blocked` | 依存待ち | 手動で追加 |

```bash
# 初回 or ラベル定義変更後（gh auth login 済み）
python3 scripts/sync-github-labels.py

# CLI で Issue 作成
gh issue create --title "..." --label "type: feature" --body "..."
gh issue create --title "..." --label "type: feature,status: blocked" --body "..."
```

PR にはラベル必須ではない（Issue の `Closes #N` で足りる）。

---

## ブランチ名

```
<type>/<kebab-case-説明>
<type>/wbs-<id>-<kebab-case-説明>    # WBS タスク着手時（例: feat/wbs-2-3-sheets-export）
```

| type | 用途 |
|------|------|
| `feat` | 機能 |
| `fix` | 不具合 |
| `docs` | ドキュメントのみ |
| `chore` | 設定・依存 |
| `refactor` | リファクタ |
| `test` | テスト |

---

## コミット

```
<type>(<scope>): <変更の要点>[ (WBS x.y)]

<why を 1〜3 文。複数論点なら箇条書き可>

Refs #<issue>          # 関連イシュー（クローズしない）
Fixes #<issue>         # マージでイシューをクローズ（fix 系）
```

**subject ルール**: 1 行・50 文字目安・末尾句点なし・命令形（「追加する」より「追加」）

---

## Pull Request

**タイトル**: コミット subject と同一（複数コミット PR はマージ後の要約 1 行）

**本文**: 見出しは英日併記。**Summary は日本語を先に**（必須）。EN 行は任意 1 行。Related のキーワード（`Closes` / `WBS:` 等）は英語のまま。

手動 PR の雛形: `bash scripts/render-pr-body.sh manual feat/your-branch`

```markdown
## Summary / 概要

- <何が変わったか（日本語・レビュー / 将来の自分向け）>
- EN: <optional one-line aligned with commit subject>

## Test plan / テスト手順

- [ ] `bash scripts/ci-check.sh` が通る
- [ ] CI `backend` / `frontend` green
- [ ] <画面・API の手動確認>

## Related

<!-- Keep English keywords for GitHub. 該当行だけ残す。なければセクションごと削除 -->
- Issue: Closes #<n>        # マージでクローズ
- Issue: Refs #<n>          # 参照のみ
- PR: Depends on #<n>       # 先にマージが必要
- PR: Related #<n>          # 関連 PR（分割 PR など）
- Branch: `<type>/<name>`    # 作業ブランチ
- WBS: <x.y> — <タスク名>
```

### Related の選び方

| 状況 | 書く内容 |
|------|----------|
| イシュー実装でマージ時に閉じたい | `Issue: Closes #N` |
| イシューに紐づくが残タスクあり | `Issue: Refs #N` |
| 別 PR の上に載せている | `PR: Depends on #N` |
| 同じ機能を分割 PR | `PR: Related #N` + 各 PR に同じ Issue |
| WBS 着手 | `WBS: 2.3 — Google Sheets 連携` |
| レビュアー向け | `Branch: feat/wbs-2-3-sheets-export` |

---

## Issue — タスク / 機能

**ラベル**: `type: feature`（docs のみなら `type: docs` に差し替え）

**タイトル**: `[WBS x.y] <短い要望>` または `<scope>: <要望>`

```markdown
## 背景
<!-- なぜ必要か。design / requirements へのリンク可 -->

## やること
- [ ] <受入可能な単位で箇条書き>
- [ ] <WBS タスクなら roadmap の ID を明記>

## 受入条件
- [ ] <完了の判定基準>
- [ ] <テスト・確認方法>

## Related
<!-- 該当する行だけ残す -->
- WBS: <x.y> — <タスク名>（[`wbs-roadmap.md`](../docs/wbs-roadmap.md)）
- Docs: [`requirements.md`](../docs/requirements.md) / [`design.md`](../docs/design.md)
- PR: #<n>（着手後に追記）
- Branch: `<type>/<name>`（着手後に追記）
- Blocks: #<issue>   # これが終わらないと着手不可
- Blocked by: #<issue>
```

---

## Issue — バグ

**ラベル**: `type: bug`

**タイトル**: `fix(<scope>): <症状の短い説明>`

```markdown
## 現象
<!-- 何が起きるか -->

## 期待
<!-- 正しい挙動 -->

## 再現手順
1.
2.

## 環境
- APP_MODE: portfolio / production
- ブラウザ / OS（UI の場合）

## Related
- Issue: Refs #<n>（重複・親イシュー）
- PR: #<n>（修正 PR 作成後）
- Branch: `fix/<name>`
```

---

## Issue — 調査（スパイク）

**ラベル**: `type: spike`

**タイトル**: `spike(<scope>): <調査テーマ>`

```markdown
## 目的
<!-- 何を決めたいか -->

## 調査項目
- [ ]

## 成果物
<!-- ドキュメント更新 / 方針決定 / 見積もり など -->

## Related
- WBS: <x.y>（該当時）
- Issue: Blocks #<n>（この調査結果で着手するイシュー）
```

---

## Issue — メンテ（Chore）

**ラベル**: `type: chore`

**タイトル**: `chore(<scope>): <内容>`

```markdown
## 背景

## やること
- [ ]

## 受入条件
- [ ]

## Related
- PR: #<n>
- Branch: `chore/<name>`
```

---
