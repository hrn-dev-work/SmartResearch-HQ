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
- [ ] PR body synced (`sync-pr-body.sh`)
- [ ] `ALLOWED_ORIGINS` / Vercel env documented if deploy changed

---

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
| 運用ドキュメントは **英語 → `---` → 日本語** | PR 本文と同じ |

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
- [ ] PR 本文同期済み
