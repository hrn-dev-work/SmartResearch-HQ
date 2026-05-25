---
name: commit-pr-style
description: >-
  Git branch workflow for SmartResearch-HQ. Use when the user asks to push, create
  a PR, commit, merge, or says プッシュまで, PR作成まで, PRまで, pushして, PR作って,
  commit, gh pr, squash merge, or git workflow. Runs commit/push/PR without extra
  permission (except destructive git). CI-gated squash merge.
summary: 「プッシュまで」「PR作成まで」で commit→push→PR まで自動実行。CI green 後 squash マージ。
user-prompt: プッシュまでお願い。／ PR作成までお願い。
category: Git・PR
disable-model-invocation: false
---

# Commit / PR / Issue / ブランチ運用（SmartResearch-HQ）

**正本**: [docs/git-workflow.md](../../../docs/git-workflow.md) + [templates.md](templates.md) + `.github/`

**リモート**: `git@github.com:hrn-dev-work/SmartResearch-HQ.git`

**Git 実行**: 危険操作以外は **ユーザー都度の許可なしで実行してよい**（`.cursor/rules/security-git.mdc`）。「プッシュまで」「PR作成まで」と言われたら **確認せず最後までやる**。

### グローバル user rule との優先

Cursor のグローバル「明示時のみ commit」と衝突する場合、**本リポジトリでは本スキル + `security-git.mdc` を優先**する。

- **プッシュまで** / **PR作成まで** / **コミットだけ** → 明示的な commit 依頼。未コミットがあれば **質問せず commit** する
- 実装のみの依頼 → commit しないが、終了時に **WSL の `git status`** で未コミットを報告する

---

## 依頼の解釈（必読）

| ユーザー | やること | 報告 |
|----------|----------|------|
| **プッシュまで** / push して | 下記 **A→E** の **E まで**（PR は作らない） | push したブランチ名 |
| **PR作成まで** / PR まで / PR 作って | 下記 **A→F** 全部 | **PR URL**（必須） |
| **マージまで** / squash マージ | **A→F** のあと CI green なら merge | マージ後の `main` HEAD |
| コミットだけ | **A→D** | commit hash |

**禁止**: 「push していいですか？」と聞いて止まる。red CI のままマージする。

### 手順 A→F（エージェントがそのまま実行）

```bash
# A. 状態確認
git branch --show-current
git status
git fetch origin

# B. main にいる + 変更あり → 作業ブランチ（未作成なら）
# bash scripts/git-start-branch.sh feat/...

# C. push 前 CI（red なら直してから進む）
bash scripts/ci-check.sh

# D. コミット（未コミットの変更がある場合）
git add <files>
git commit -m "$(cat <<'EOF'
<type>(<scope>): English subject

English why (1–2 sentences).

---

日本語の why（1–2 文）。

Refs #
EOF
)"

# E. プッシュまで
bash scripts/git-ship.sh push

# F. PR作成まで（依頼に PR が含まれるとき、または post-push で未作成のとき）
bash scripts/git-ship.sh pr
# または本文を書き分けたいとき:
# gh pr create --base main \
#   --title "$(bash scripts/render-pr-title.sh)" \
#   --body "$(bash scripts/render-pr-body.sh manual "$(git branch --show-current)")"
```

**フック未設定時**（初回のみ）: `bash scripts/install-git-hooks.sh`

**マイルストーン PR**（phase2 / phase3）: 本文は [templates.md](templates.md) の例に合わせて `gh pr edit` または `scripts/update-open-pr-bodies.sh` を参考に **Summary / Commits / Test plan / Related** を埋める。

---

## ブランチ運用（必須）

### 鉄則

- **既定ブランチ `main` では作業しない**（直接 commit / push 禁止）
- 1 作業 = 1 ブランチ = 1 PR
- **マージは CI green 後**に squash。マージ後は `main` を `pull`

### 着手前

```bash
git branch --show-current
git status
git fetch origin
```

| 現在 | 動き |
|------|------|
| `main` + 変更 | **先に作業ブランチ** |
| 作業ブランチ | そのまま commit / PR |

```bash
bash scripts/git-start-branch.sh feat/wbs-2-3-説明
```

---

## CI

| Job | 内容 |
|-----|------|
| backend | Ruff lint + format check + pytest |
| frontend | ESLint + `next build` |

ローカル: `bash scripts/ci-check.sh`

---

## 分析（コミット・PR 文案を書く前）

```bash
git status
git diff
git diff --staged
git log --oneline -10
git branch --show-current
git diff main...HEAD
gh issue list --limit 20
gh pr list --limit 20
```

## コミット

**subject**: 英語のみ（Conventional Commits）。**body**: 英語 → `---` → 日本語（why を簡潔に）。

雛形: `bash scripts/render-commit-msg.sh feat spreadsheet "add export skeleton (WBS 2.3)"`

## PR

### タイトル（英語のみ）

雛形: `bash scripts/render-pr-title.sh [base] [branch]`

### 本文

英語ブロック → `---` → 日本語ブロック。**Summary / Commits / Test plan / Related**。詳細 [templates.md](templates.md)。

雛形: `bash scripts/render-pr-body.sh manual <branch>`

## 禁止

- `git config` 変更、force push、`--no-verify`
- `main` / `master` への直接 commit / push
- **CI red のマージ**
- 秘密情報のコミット

## 参照

- [docs/git-workflow.md](../../../docs/git-workflow.md)
- [examples.md](examples.md)
- `scripts/git-ship.sh` — push / PR 一発
- `.github/workflows/ci.yml`
