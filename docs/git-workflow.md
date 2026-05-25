# Git ブランチ運用

SmartResearch-HQ の **ブランチ・コミット・PR・マージ** の規約。個人開発向け **GitHub Flow（簡易版）**。

文言テンプレ: ローカル `.cursor/skills/commit-pr-style/` を参照（**`.cursor/` 全体が gitignore**。公開 clone には含まれない。使い方: `docs/local/cursor-usage.md`）。

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
gh pr create --base main --title "$(bash scripts/render-pr-title.sh)" --body "$(bash scripts/render-pr-body.sh manual feat/your-branch)"
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
| **2. コミット** | 作業ブランチ上でコミット（Conventional Commits・subject 英語、body は `英語` → `---` → `日本語`） |
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
feat(spreadsheet): add Sheets export skeleton (WBS 2.3)

Call real Sheets API in production only; portfolio returns count.

---

production のみ実 API を呼び、portfolio は件数のみ返す。

Refs #42
EOF
)"
git push -u origin HEAD
gh pr create --repo hrn-dev-work/SmartResearch-HQ --title "feat(spreadsheet): add Sheets export skeleton (WBS 2.3)" --body "$(cat <<'EOF'
## Summary

- Add Sheets export service skeleton (WBS 2.3)

---

- Sheets export サービスの骨組みを追加（WBS 2.3）

## Test plan

- [ ] `bash scripts/ci-check.sh` passes
- [ ] CI green

---

- [ ] `bash scripts/ci-check.sh` が通る
- [ ] CI green

## Related

- Issue: Closes #42
- Branch: `feat/wbs-2-3-sheets-export`
- WBS: 2.3

---

- イシュー: Closes #42
- ブランチ: `feat/wbs-2-3-sheets-export`
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

### 3.1 push と PR 作成

**エージェント / 手動**

| 依頼 | コマンド |
|------|----------|
| プッシュまで | `bash scripts/git-ship.sh push` |
| PR 作成まで | `bash scripts/git-ship.sh pr` |

**初回セットアップ（ローカル hook、推奨）**

```bash
bash scripts/install-git-hooks.sh   # core.hooksPath=.githooks
```

- `pre-commit` → WBS ロードマップ + README チェック同期
- `post-push` → **既存 PR** のチェックボックス同期のみ（PR は自動作成しない）
- PR 新規作成は **`git-ship.sh pr`** または `ensure-pr.sh`

**代替（旧名）**

```bash
bash scripts/git-push-pr.sh    # = git-ship.sh pr
```

手動 PR の例（自動を使わない場合）:

```bash
gh pr create --base main --title "$(bash scripts/render-pr-title.sh)" --body "$(bash scripts/render-pr-body.sh manual feat/your-branch)"
```

`gh pr create --fill` は使わない（コミット subject から英語のみの本文になりやすい）。

### 3.2 PR 本文の CI チェック自動同期

CI の `backend` / `frontend` が green になると、ワークフロー `sync-pr-checkboxes` が PR 本文の Test plan 行（`ci-check.sh` / `backend / frontend`）を `[x]` に更新する。

**`GitHub Actions is not permitted to create or approve pull requests` が出る場合**

組織またはリポジトリで、既定の `GITHUB_TOKEN` による PR 編集が禁止されている。次のいずれかで解消する。

| 方法 | 手順 |
|------|------|
| **A. リポジトリ設定** | Settings → Actions → General → Workflow permissions を **Read and write** に。組織で制限している場合は、Org の「Allow GitHub Actions to create and approve pull requests」を有効化 |
| **B. PAT シークレット（推奨・組織ロック時）** | fine-grained PAT を作成（対象リポジトリ、**Pull requests: Read and write**、Contents: Read）→ Settings → Secrets and variables → Actions → **`GH_PR_SYNC_TOKEN`** に登録。`sync-pr-checkboxes` と **Auto PR**（`auto-pr.yml`）の両方が `secrets.GH_PR_SYNC_TOKEN \|\| github.token` を使用 |

ローカルでは `gh auth login` 済みなら push 後の `post-push` または手動で同期できる:

```bash
bash scripts/sync-pr-checkboxes.sh    # 現在ブランチの PR
bash scripts/sync-pr-checkboxes.sh 5  # PR 番号指定
```

### 3.3 Cursor + UNC（`\\wsl.localhost\...`）で scripts が `M` になる

**WSL ターミナルで `git diff` が空なのに、Cursor の Source Control だけ変更がある**ときは、ロジック変更ではなく **改行（CRLF↔LF）または実行権限** のことが多い。

| 確認 | コマンド（WSL） |
|------|------------------|
| 実変更か | `git diff --stat scripts/dev.sh` |
| 改行だけか | 差分の各行が `-` と `+` で中身同一 → CRLF |

**予防（リポジトリ済み）**

- `.gitattributes` — `*.sh` / `scripts/**` / `.githooks/**` を LF
- `.vscode/settings.json` — `"git.path": "\\\\wsl.localhost\\Ubuntu\\usr\\bin\\git"`
- `bash scripts/install-git-hooks.sh` — `core.filemode false`

**直し（1 回）**

```bash
cd ~/workspace/SmartResearch-HQ
find scripts .githooks -type f -exec sed -i 's/\r$//' {} +
git add --renormalize scripts/ .githooks/
git status -sb
```

エージェントは Git を **WSL 内**で実行し、UNC 上の PowerShell `git` に依存しない（`~/.cursor/skills/wsl-agent-invoke/SKILL.md`）。

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
gh pr create --base main --title "$(bash scripts/render-pr-title.sh)" --body "$(bash scripts/render-pr-body.sh manual feat/your-branch)"
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
- `phase1` は legacy スナップショット。**新規作業・push は `main` 系ブランチのみ**
- force push は禁止
- **コミット明示**: 「プッシュまで」「PR作成まで」「コミットだけ」→ commit 可（`.cursor/rules/security-git.mdc`）。実装のみ → 終了時に `git status` 報告

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

---

## 8. Cursor on Windows + WSL（phantom diff / コミット漏れ見え）

ワークスペースが `\\wsl.localhost\...` のとき、**Source Control は WSL の git を使う**。

| 設定 | 値 |
|------|-----|
| `.vscode/settings.json` | `"git.path": "\\\\wsl.localhost\\Ubuntu\\usr\\bin\\git"` |
| ローカル hook（推奨） | `bash scripts/install-git-hooks.sh`（`core.filemode false`） |
| エージェントの git | **WSL bash 内のみ**（PowerShell / UNC の `git` 禁止） |

| 症状 | 確認 | 対処 |
|------|------|------|
| Cursor だけ大量 `M`、WSL で `git diff` が空 | `git diff --stat <file>` | `git.path` を WSL に。`install-git-hooks.sh` |
| 全行 `-`/`+`（中身同じ） | CRLF | `sed -i 's/\r$//' <file>` → `git add --renormalize`。`.gitattributes` の `eol=lf` |
| 実装したのに commit されていない | WSL `git status -sb` | 「プッシュまで」で `git-ship.sh push`。`stop` フックが未コミットを followup |

Shell 出力が空になるときは WSL で結果をファイルに書き、Read する（`wsl-agent-invoke` スキル参照）。
