---
name: commit-pr-style
description: >-
  Git branch workflow for SmartResearch-HQ: branch from main, commit, push, PR,
  CI-gated squash merge. Unified templates and Related links. Safe git ops allowed;
  blocks force push and default-branch direct commits. Use for git, PR, CI, merge.
summary: 作業ブランチで commit/push/PR まで。CI（backend+frontend）green 後に squash マージ。
user-prompt: 作業ブランチを切って、CI を通して commit・push・PR まで。green なら squash マージして。
category: Git・PR
disable-model-invocation: false
---

# Commit / PR / Issue / ブランチ運用（SmartResearch-HQ）

**正本**: [docs/git-workflow.md](../../../docs/git-workflow.md) + [templates.md](templates.md) + `.github/`

**リモート**: `git@github.com:hrn-dev-work/SmartResearch-HQ.git`

**Git 実行**: 危険操作以外は **明示依頼なしで可**（`.cursor/rules/security-git.mdc`）

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

### フロー — commit → CI → push → PR

1. 分析（下記）
2. `bash scripts/ci-check.sh`（push 前推奨）
3. `git add` → `git commit`（`main` でないこと）
4. `git push -u origin HEAD`
5. `gh pr create --base main --title "$(bash scripts/render-pr-title.sh)" --body "$(bash scripts/render-pr-body.sh manual "$(git branch --show-current)")"`

### フロー — マージ（CI green 必須）

```bash
gh pr checks
# backend / frontend が pass であること
gh pr merge --squash --delete-branch
git checkout main && git pull --ff-only origin main
```

CI red → 修正して push → 再実行を待つ。**マージしない。**

---

## CI

| Job | 内容 |
|-----|------|
| backend | Ruff lint + format check + pytest |
| frontend | ESLint + `next build` |

ローカル: `bash scripts/ci-check.sh`

---

## 分析

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

```
<type>(<scope>): <English summary>[ (WBS x.y)]

<English why>

---

<日本語の why>

Refs #N / Fixes #N
```

雛形: `bash scripts/render-commit-msg.sh feat spreadsheet "add export skeleton (WBS 2.3)"`

PR タイトル = subject（英語）。body の `---` 以降は PR 本文の日本語ブロックに流用可。

**自動化**（意識不要）: `pre-commit` → WBS/README 同期 / `post-push` → PR + チェックボックス / CI → PR チェック同期。

## PR

### タイトル（英語のみ・必須）

- **Conventional Commits** 形式: `type(scope): summary`
- **1 コミット PR**: subject と同一
- **複数コミット PR**: 最新コミット名を使わない。変更全体の **英語 1 行要約**
- **phase2 / phase3 等**: `Phase N: <English summary>`（例: `Phase 3: Redis health + manual ASIN (WBS 3.5–3.6)`）

雛形: `bash scripts/render-pr-title.sh [base] [branch]`

### 本文

[templates.md](templates.md) — 英語ブロック（Summary / Commits / Test plan / Related）→ `---` → 日本語ブロック（見出しに `(Summary)` 等）。箇条書き `*`。

Test plan は `* [ ]` チェックボックス。CI green 後は hook / CI job が自動 `[x]`。

`gh pr create --fill` は使わない。雛形: `bash scripts/render-pr-body.sh manual <branch>`

```bash
gh pr create --base main \
  --title "$(bash scripts/render-pr-title.sh)" \
  --body "$(bash scripts/render-pr-body.sh manual "$(git branch --show-current)")"
```

## Issue

[templates.md](templates.md) 参照。ラベル: `python3 scripts/sync-github-labels.py`

## 禁止

- `git config` 変更、force push、`--no-verify`
- `main` / `master` への直接 commit / push
- **CI red のマージ**
- 秘密情報のコミット
- **日本語 PR タイトル**、**複数コミット PR で最新コミット名をタイトルにする**
- **日本語コミット subject**、**body に `---` なしの日英混在**

## 参照

- [docs/git-workflow.md](../../../docs/git-workflow.md)
- [examples.md](examples.md)
- `.github/workflows/ci.yml`
