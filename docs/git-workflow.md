# Git ブランチ運用

SmartResearch-HQ の **ブランチ・コミット・PR・マージ** の規約。個人開発向け **GitHub Flow（簡易版）**。

文言テンプレ: ローカルに `.cursor/skills/commit-pr-style/` がある場合は参照（公開 clone には含まれない）。

---

## 0. リポジトリ

| 項目 | 値 |
|------|-----|
| GitHub | [hrn-dev-work/SmartResearch-HQ](https://github.com/hrn-dev-work/SmartResearch-HQ) |
| SSH（推奨） | `git@github.com:hrn-dev-work/SmartResearch-HQ.git` |
| HTTPS | `https://github.com/hrn-dev-work/SmartResearch-HQ.git` |
| **既定ブランチ** | **`main`** |

### 初回セットアップ（WSL）

**A. 新規 clone**

```bash
cd ~/workspace
git clone git@github.com:hrn-dev-work/SmartResearch-HQ.git
cd SmartResearch-HQ
```

**B. ローカル已有・リモート未設定**

```bash
cd ~/workspace/SmartResearch-HQ
git remote add origin git@github.com:hrn-dev-work/SmartResearch-HQ.git
git fetch origin
git branch -M main
git push -u origin main   # 初回のみ。以降は PR 経由
```

**C. まだ `git init` していない**

```bash
cd ~/workspace/SmartResearch-HQ
git init
git remote add origin git@github.com:hrn-dev-work/SmartResearch-HQ.git
git add .
git commit -m "chore: initial commit"
git branch -M main
git push -u origin main   # 初回のみ
```

**D. SSH 鍵・gh CLI**

```bash
ssh -T git@github.com          # Hi hrn-dev-work! と出れば OK
gh auth login                  # PR / Issue / ラベル同期用
gh repo set-default hrn-dev-work/SmartResearch-HQ
python3 scripts/sync-github-labels.py
```

**main に未コミット変更がある場合**（ブランチ運用へ移行）:

```bash
git checkout -b chore/git-workflow-setup
git add .
git commit -m "chore: Git ブランチ運用規約と GitHub テンプレを追加"
git push -u origin HEAD
gh pr create --base main --title "..." --body "$(bash scripts/render-pr-body.sh manual feat/your-branch)"
```

---

## 1. ブランチ構成

```
main                              # 既定・マージ先（phase1 より進む）
phase1                            # Phase 1 完了スナップショット（固定・main と同期しない）
├── phase2                        # マイルストーン（Phase 2 → main へ PR）
├── phase3                        # マイルストーン（Phase 3 → main へ PR）
├── feat/wbs-2-3-sheets-export    # 機能・WBS タスク
├── fix/review-empty-candidates   # バグ修正
└── docs/wbs-phase2-update        # ドキュメントのみ
```

| ブランチ | 用途 | 寿命 |
|----------|------|------|
| `main` | マージ先・デプロイ/デモの基準 | 常設 |
| `phase1` | **Phase 1 完了時点の固定スナップショット**（`c81f5ad` 付近） | 常設・**main と同一にしない** |
| `phase2` / `phase3` | Phase マイルストーン作業 → PR で `main` へ | Phase 完了後も参照用に残すか削除 |
| `feat/*` | 機能・WBS 実装 | 1 Issue / 1 WBS タスク = 1 ブランチ |
| `fix/*` | 不具合修正 | 修正単位で短命 |
| `docs/*` | 仕様・README のみ | 短命 |
| `chore/*` | ツール・ラベル・CI | 短命 |
| `spike/*` | 調査（コードを残さないことも多い） | 調査完了でマージ or 破棄 |

### 命名

```
<type>/<kebab-case>
<type>/wbs-<id>-<kebab-case>    # WBS 着手時（例: feat/wbs-2-3-sheets-export）
```

`<type>` はコミット type（`feat` / `fix` / `docs` / `chore` / `spike`）と揃える。

---

## 2. 基本フロー（Issue → ブランチ → PR → マージ）

```
main ──pull──► 作業ブランチ作成 ──commit──► push ──PR──► main へマージ ──pull──► 次タスク
         ▲                                                      │
         └──────────────── delete branch ◄──────────────────────┘
```

| 段階 | やること |
|------|----------|
| **0. 着手前** | `main` を最新化。Issue があれば作成（任意）。WBS 1 件にスコープ固定 |
| **1. ブランチ** | `main` から作業ブランチを切る。**main のまま作業しない** |
| **2. コミット** | 作業ブランチ上でコミット（Conventional Commits） |
| **3. push** | `git push -u origin HEAD` または `bash scripts/git-push-pr.sh` |
| **4. PR** | 自動（下記 §3.1）または手動 `gh pr create`。`Closes #N` / `WBS:` / `Branch:` を本文に |
| **5. マージ** | GitHub UI または `gh pr merge --squash`（推奨: squash） |
| **6. 片付け** | リモートブランチ削除 → ローカルで `main` に戻って `pull` |

### 1 ブランチ = 1 目的

- WBS 2.3 だけ、バグ #55 だけ、など **1 PR = 1 論点**
- 大きい WBS は Issue で分割し、`Depends on` / `Related` で PR をつなぐ

---

## 3. コマンド例（WSL）

### 作業開始

```bash
cd ~/workspace/SmartResearch-HQ
git fetch origin
git checkout main
git pull --ff-only origin main
git checkout -b feat/wbs-2-3-sheets-export
```

ショートカット: `bash scripts/git-start-branch.sh feat/wbs-2-3-sheets-export`

### コミット → push → PR

```bash
git status
git add <files>
git commit -m "$(cat <<'EOF'
feat(spreadsheet): Sheets export サービスの骨組みを追加 (WBS 2.3)

Refs #42
EOF
)"
git push -u origin HEAD
gh pr create --repo hrn-dev-work/SmartResearch-HQ --title "feat(spreadsheet): Sheets export サービスの骨組みを追加 (WBS 2.3)" --body "$(cat <<'EOF'
## Summary

- Add Sheets export service skeleton (WBS 2.3) _(Sheets export 骨組み)_

## Test plan

- [ ] `bash scripts/ci-check.sh`
- [ ] CI green

## Related

- Issue: Closes #42
- Branch: `feat/wbs-2-3-sheets-export`
- WBS: 2.3
EOF
)"
```

### マージ後

```bash
gh pr merge --squash --delete-branch
git checkout main
git pull --ff-only origin main
```

### 3.1 push 後の PR 自動作成

**初回セットアップ（ローカル hook、推奨）**

```bash
bash scripts/install-git-hooks.sh   # core.hooksPath=.githooks
```

以降、`git push` の直後に **open PR がなければ** `gh pr create` 相当を実行（`main` / `master` は除外）。

**代替: push + PR を一発**

```bash
bash scripts/git-push-pr.sh
```

**GitHub Actions（リモートでも自動）**

[`.github/workflows/auto-pr.yml`](../.github/workflows/auto-pr.yml) — `main` 以外へ push されたとき、open PR がなければ `main` 向け PR を作成。

| 方法 | いつ動く | 要件 |
|------|----------|------|
| `post-push` hook | ローカル `git push` 後 | `gh auth login` |
| `git-push-pr.sh` | スクリプト実行時 | 同上 |
| Auto PR workflow | `origin` へ push 後 | リポジトリ Actions 有効 |

手動 PR の例（自動を使わない場合）:

```bash
gh pr create --base main --title "..." --body "$(bash scripts/render-pr-body.sh manual feat/your-branch)"
```

`gh pr create --fill` は使わない（コミット subject から英語のみの本文になりやすい）。

---

## 4. マイルストーン branch（Phase 1 / 2 / 3）

### phase1 は main と別物

| ブランチ | 指すコミット | 役割 |
|----------|--------------|------|
| **`phase1`** | Phase 1 完了（WBS 1.1–1.6、`c81f5ad`） | **固定スナップショット**。以降更新しない |
| **`main`** | 統合ブランチ（現在は phase1 より 2 commits 先行） | PR のマージ先。Phase 2 以降はここへ入る |

`phase1` を `main` と同じコミットに **fast-forward しない**。Phase 1 の成果物だけを残す参照用ブランチとする。

```bash
# Phase 1 スナップショットを確認
git fetch origin
git log -1 --oneline origin/phase1   # feat: Phase 1 - design docs ...
git log -1 --oneline origin/main     # main は git-workflow 等で先行しうる
```

### Phase 2 以降

Phase 2 / 3 の作業は **`main` から** `phase2` / `phase3` を切り、完了後は PR で **`main` へマージ**（`phase1` へはマージしない）。

```bash
git fetch origin
git checkout main
git pull --ff-only origin main
git checkout -b phase2
# ... 実装 ...
git push -u origin phase2
gh pr create --base main --title "..." --body "$(bash scripts/render-pr-body.sh manual feat/your-branch)"
```

通常の機能追加は `feat/*` を `main` から切る。

---

## 5. GitHub リポジトリ設定（推奨）

対象: [hrn-dev-work/SmartResearch-HQ — Settings](https://github.com/hrn-dev-work/SmartResearch-HQ/settings)

### Branch protection（既定ブランチ `main`）

[Branches 設定を開く](https://github.com/hrn-dev-work/SmartResearch-HQ/settings/branches) → **Add branch ruleset** または **Add classic rule**

| 設定 | 推奨 | 理由 |
|------|------|------|
| Branch name pattern | `main` | |
| Require a pull request before merging | ✅ | 既定ブランチ直 push を防ぐ |
| Require status checks to pass | ✅ | **`backend`** と **`frontend`** を必須に |
| Require approvals | ❌（個人開発） | 自分 PR は不要 |
| Allow force pushes | ❌ | 履歴保護 |
| Allow deletions | ❌ | main 削除防止 |

### Pull Requests

[General → Pull Requests](https://github.com/hrn-dev-work/SmartResearch-HQ/settings)

| 設定 | 推奨 |
|------|------|
| Allow squash merging | ✅（既定のマージ方法に） |
| Allow merge commits | 任意 |
| Allow rebase merging | 任意 |
| Automatically delete head branches | ✅ |

### ラベル・Issue テンプレ

```bash
cd ~/workspace/SmartResearch-HQ
gh repo set-default hrn-dev-work/SmartResearch-HQ
python3 scripts/sync-github-labels.py
```

Issue 作成: [New issue](https://github.com/hrn-dev-work/SmartResearch-HQ/issues/new/choose)

---

## 5.1 CI（マージ可否の判定）

ワークフロー: [`.github/workflows/ci.yml`](../.github/workflows/ci.yml)

| Job | 内容 |
|-----|------|
| **backend** | Ruff lint / format check / pytest |
| **frontend** | ESLint / `next build` |

**PR では両方 green がマージ条件**（branch protection 設定後）。

### ローカル確認

```bash
bash scripts/ci-check.sh
```

push 前・マージ前に推奨。

### マージ

```bash
gh pr checks                    # backend / frontend が pass か確認
gh pr merge --squash --delete-branch
git checkout main && git pull --ff-only origin main
```

CI が red のときは **マージしない**。修正 → push → CI 再実行を待つ。

---

## 6. エージェント向けルール

- 既定ブランチ（`main`）でコミット依頼 → **先に作業ブランチを切る**
- 既定ブランチへの直接 push はしない
- force push は禁止

---

## 7. ユーザー依頼の例

```
WBS 2.3 用のブランチを切って、コミット・push・PR まで。
```

```
main にいる変更を feature ブランチに移して PR 作成して。
```

```
PR #12 を squash マージして、main を最新化して。
```
