---
name: commit-pr-style
description: >-
  Git branch workflow for SmartResearch-HQ: branch from phase1, commit, push, PR,
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

- **既定ブランチ `phase1` では作業しない**（直接 commit / push 禁止）
- 1 作業 = 1 ブランチ = 1 PR
- **マージは CI green 後**に squash。マージ後は `phase1` を `pull`

### 着手前

```bash
git branch --show-current
git status
git fetch origin
```

| 現在 | 動き |
|------|------|
| `phase1` + 変更 | **先に作業ブランチ** |
| 作業ブランチ | そのまま commit / PR |

```bash
bash scripts/git-start-branch.sh feat/wbs-2-3-説明
```

### フロー — commit → CI → push → PR

1. 分析（下記）
2. `bash scripts/ci-check.sh`（push 前推奨）
3. `git add` → `git commit`（`phase1` でないこと）
4. `git push -u origin HEAD`
5. `gh pr create --base phase1 ...`

### フロー — マージ（CI green 必須）

```bash
gh pr checks
# backend / frontend が pass であること
gh pr merge --squash --delete-branch
git checkout phase1 && git pull --ff-only origin phase1
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
git diff phase1...HEAD
gh issue list --limit 20
gh pr list --limit 20
```

## コミット

```
<type>(<scope>): <要点>[ (WBS x.y)]
```

Body に **why**。Issue: `Refs #N` / `Fixes #N`

## PR

タイトル = commit subject（英語）。本文は [templates.md](templates.md)（**3 セクション・英語主、日本語は _(…)_ で同行**）。

`gh pr create --fill` は使わない（英語のみになりやすい）。雛形: `bash scripts/render-pr-body.sh manual <branch>`

Test plan に `- [ ] CI backend / frontend green` を入れる。

```bash
gh pr create --base phase1 --title "..." --body "$(cat <<'EOF' ... EOF)"
```

## Issue

[templates.md](templates.md) 参照。ラベル: `python3 scripts/sync-github-labels.py`

## 禁止

- `git config` 変更、force push、`--no-verify`
- `phase1` / `main` への直接 commit / push
- **CI red のマージ**
- 秘密情報のコミット

## 参照

- [docs/git-workflow.md](../../../docs/git-workflow.md)
- [examples.md](examples.md)
- `.github/workflows/ci.yml`
