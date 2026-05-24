#!/usr/bin/env bash
# Bootstrap: first PR for git-workflow / GitHub templates (run once from phase1).
# Usage: bash scripts/git-first-pr.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BASE="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo phase1)"
BRANCH="chore/git-workflow-setup"

if [[ "$(git branch --show-current)" == "$BASE" ]]; then
  git checkout -b "$BRANCH"
else
  git checkout "$BRANCH" 2>/dev/null || git checkout -b "$BRANCH"
fi

git add -A
if git diff --cached --quiet; then
  echo "Nothing to commit."
  exit 0
fi

git commit -m "$(cat <<'EOF'
chore: Git ブランチ運用・GitHub テンプレ・エージェント設定を追加

phase1 直コミットをやめ、作業ブランチ→PR→squash マージのフローに統一する。
Issue/PR テンプレ、ラベル定義、commit-pr-style スキル、git-workflow 規約を含む。
EOF
)"

git push -u origin HEAD
gh repo set-default hrn-dev-work/SmartResearch-HQ
python3 scripts/sync-github-labels.py

if gh pr view --head "$BRANCH" >/dev/null 2>&1; then
  gh pr view --head "$BRANCH" --web
else
  gh pr create --base "$BASE" --title "chore: Git ブランチ運用・GitHub テンプレ・エージェント設定を追加" --body "$(cat <<'EOF'
## Summary

- Add git-workflow docs, commit-pr-style skill, CI, and GitHub templates
- Track .cursor rules needed for GitHub workflow

## 概要

- Git ブランチ運用規約（docs/git-workflow.md）と commit-pr-style スキルを追加
- PR / Issue テンプレ、ラベル定義（.github/）、git-start-branch.sh を追加
- .gitignore を更新し、GitHub 運用に必要な .cursor / AGENTS.md を追跡対象に

## Test plan

- [ ] `bash scripts/ci-check.sh` passes
- [ ] CI `backend` / `frontend` green

## テスト手順

- [ ] `bash scripts/ci-check.sh` が通る
- [ ] CI `backend` / `frontend` green
- [x] 作業ブランチ `chore/git-workflow-setup` から PR 作成
- [ ] squash マージ後、以降は feat/* ブランチから作業

## Related

- Branch: `chore/git-workflow-setup`
- WBS: —（開発基盤）

## 関連

- ブランチ: `chore/git-workflow-setup`
- WBS: —（開発基盤）
EOF
)"
fi

echo "Done. Merge with: gh pr merge --squash --delete-branch"
