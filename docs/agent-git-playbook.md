# Agent & Git playbook — recurrence prevention

For Cursor agents and maintainers. Public clone: use `scripts/git-ship.sh` and this doc (not `AGENTS.md`, which is gitignored locally).

---

## Golden rules

| Rule | Why |
|------|-----|
| Work in **WSL** (`~/workspace/...`), not `\\wsl.localhost\` only | Agent shell + phantom git diffs |
| **`main` first**: merge `origin/main` **before** large commits | Avoids README/i18n merge conflicts after the fact |
| **PR作成まで** = `bash scripts/git-pr-complete.sh` | Single canonical script |
| Never `git add AGENTS.md` / `.cursor/` | gitignored — use `bash scripts/git-add-safe.sh` |
| UI copy in **`messages/ja.ts` + `en.ts`** | Type is `messages/types.ts` (`DeepString`) |
| Open PR: **`gh pr list --head <branch> --state open`** | Merged PRs must not block new PRs; no `gh pr view --head` |
| PR create: **`ensure-pr.sh`** (REST fallback) | Avoids `projectCards` GraphQL errors |
| After push: **`sync-pr-body.sh`** | Commits list + CI checkboxes stay current |
| PR body format: **`validate-pr-body.sh`** | EN `**Section**` → `---` → JA; rejects `## Summary` legacy |
| Docs for operators: **English → `---` → 日本語** | Same as PR body convention |

---

## User request → command

| User says | Run |
|-----------|-----|
| プッシュまで / push | `bash scripts/git-ship.sh push` |
| PR作成まで / PR まで | `bash scripts/git-pr-complete.sh` |
| merge conflict in progress | `bash scripts/resolve-merge-main-keep-i18n.sh` |
| behind main | `bash scripts/git-merge-main-safe.sh` (clean tree) |
| local CI | `bash scripts/ci-check.sh` |

---

## Agent shell failure (Cursor)

If the agent reports empty terminal output but your WSL terminal works:

1. **F1** → `WSL: Reopen Folder in WSL`
2. Cursor Settings → Agents → **Legacy Terminal Tool** ON → restart Cursor
3. Agent must run: `wsl.exe -d Ubuntu bash -lc 'cd ~/workspace/SmartResearch-HQ && …'`
4. Do **not** ask the user to run commands unless step 1–3 fail

See `docs/local/agent-shell-fix.md` on a machine with `docs/local/` checked out.

---

## PR title (multi-commit branches)

Do not copy the latest commit subject. Example:

`feat(portfolio): deploy setup, mock API parity, and ja/en UI`

```bash
bash scripts/render-pr-title.sh main "$(git branch --show-current)"
gh pr edit <num> --title "$(bash scripts/render-pr-title.sh)"
```

---

## Checklist before merge

- [ ] `bash scripts/ci-check.sh` green
- [ ] `frontend`: JA / EN toggle smoke-tested
- [ ] PR body synced (`sync-pr-body.sh`) and valid (`validate-pr-body.sh <pr>`)
- [ ] `ALLOWED_ORIGINS` / Vercel env documented if deploy changed

---

## PR body (bilingual template)

**Required shape** (see `.cursor/skills/commit-pr-style/templates.md`):

1. English block: `**Summary**`, `**Commits**`, `**Test plan**`, `**Related**`
2. Horizontal rule: `---`
3. Japanese block: `**概要 (Summary)**`, `**コミット (Commits)**`, …

**Do not** use GitHub Action legacy format (`## Summary`, single language).

```bash
# Generate + push to GitHub
bash scripts/sync-pr-body.sh "$(git branch --show-current)" main

# Validate only
bash scripts/validate-pr-body.sh 14
bash scripts/validate-pr-body.sh --file /tmp/body.md
```

`.github/workflows/auto-pr.yml` uses the same `render-pr-body.sh` + `validate-pr-body.sh` on create.

---

## Public doc incidents (learned)

| Symptom | Cause | Fix |
|---------|-------|-----|
| README English-only merged (PR #34) | No CI/pre-commit on public md | validate-public-docs.sh + doc-conventions.md |

See doc-conventions.md.

---

## PR body incidents (learned)

| Symptom | Cause | Fix |
|---------|-------|-----|
| `## Summary` only, no Japanese | Old `auto-pr.yml` inline template | `sync-pr-body.sh` + updated workflow |
| Body is `@/tmp/...` on GitHub | `gh api -f body=@file` | `gh_api_patch_pr_body` (python3 JSON) |
| `gh pr edit` / `gh pr view` GraphQL error | Projects classic deprecation | REST via `gh_pr_edit_body_safe` |
| `scripts/gh-pr-branch.sh` missing | Mistaken cleanup as one-off script | Listed in `.gitignore` comment + `check-pr-tooling.sh` |
| Agent shell empty output | Cursor on UNC path | WSL reopen + `wsl.exe bash -lc` + log to file |

Pre-push self-check: `bash scripts/check-pr-tooling.sh` (also runs at start of `ci-check.sh`).

---

# エージェント・Git プレイブック — 再発防止

公開 clone では `AGENTS.md` は無く、本書と `scripts/` を正とする。

## 鉄則

| ルール | 理由 |
|--------|------|
| **WSL** で `~/workspace/...` を開く | エージェント Shell / phantom diff 回避 |
| 大きな commit **前に** `origin/main` をマージ | 後からの README・i18n コンフリクト防止 |
| **PR作成まで** = `bash scripts/git-pr-complete.sh` | 入口を一本化 |
| `git add` に **gitignore ファイルを含めない** | `bash scripts/git-add-safe.sh` を使う |
| UI 文言は **`messages/ja.ts` と `en.ts`** | 型は `messages/types.ts` |
| PR 参照は **`gh pr list --head <branch> --state open`** | マージ済み PR が新規作成を阻害しない |
| PR 作成は **`ensure-pr.sh`**（REST フォールバック） | projectCards GraphQL エラー回避 |
| push 後は **`sync-pr-body.sh`** | PR 本文の Commits / CI チェックを更新 |
| PR 本文は **`validate-pr-body.sh`** | 英日二段・`**Section**` 必須（`## Summary` 禁止） |
| 運用ドキュメントは **英語 → `---` → 日本語** | PR 本文と同じ |
| **`check-pr-tooling.sh`** | push/CI 前に PR 本文ツールの自己検査 |

## PR 本文インシデント（教訓）

| 症状 | 原因 | 対策 |
|------|------|------|
| `## Summary` のみ | 旧 auto-pr テンプレ | `sync-pr-body.sh` + workflow 更新 |
| 本文が `@/tmp/...` | `gh api -f body=@file` | python3 JSON（`gh_api_patch_pr_body`） |
| `gh pr edit` GraphQL エラー | Projects classic 廃止 | REST（`gh_pr_edit_body_safe`） |
| `gh-pr-branch.sh` 欠落 | 誤って one-off 削除 | `.gitignore` コメント + `check-pr-tooling.sh` |

## 依頼 → コマンド

| 依頼 | コマンド |
|------|----------|
| プッシュまで | `bash scripts/git-ship.sh push` |
| PR作成まで | `bash scripts/git-pr-complete.sh` |
| マージ途中 | `bash scripts/resolve-merge-main-keep-i18n.sh` |
| main が古い | `bash scripts/git-merge-main-safe.sh`（未コミットなし） |
| ローカル CI | `bash scripts/ci-check.sh` |

## Cursor の Shell が空のとき

1. **WSL: Reopen Folder in WSL**
2. **Legacy Terminal Tool** ON → Cursor 再起動
3. エージェントは `wsl.exe -d Ubuntu bash -lc '...'` を使う
4. それでもダメならユーザーに手元ターミナルで `git-pr-complete.sh`（エージェントの代替案内）

## マージ前チェック

- [ ] `ci-check.sh` 成功
- [ ] フロント JA/EN 確認
- [ ] PR 本文同期済み（`sync-pr-body.sh`）かつ `validate-pr-body.sh <pr>` 成功
