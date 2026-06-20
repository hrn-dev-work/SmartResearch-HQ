# Cursor agent shell — empty output (WSL)

When **your WSL terminal works** but the **Cursor agent Shell returns nothing**, use this checklist before asking the user to run commands manually.

---

## Root causes (verified on this repo)

| # | Cause | Symptom | Why |
|---|--------|---------|-----|
| 1 | **Pipe capture bug** | `wsl … git status \| head` → empty Shell stdout; same command writes bytes to a file | Cursor Shell on Windows often drops **piped** WSL stdout (non-TTY). Simple `echo` and file redirects still work. |
| 2 | **UNC vs WSL filesystem view** | Editor shows files; WSL checkout is old branch / missing paths | Workspace opened as `\\wsl.localhost\...` without **Reopen in WSL** — two views of the same repo. |
| 3 | **PowerShell host + quoting** | Intermittent failures, broken heredocs in `wsl -lc '…'` one-liners | Agent Shell runs PowerShell; nested quotes in long git/gh commands fail silently or truncate. |
| 4 | **No exit code in tool result** | Message: *"The shell command returned no exit status"* | Agent cannot tell success from failure when stdout is empty — must read `.agent-local/latest.exit` or `.git/logs/HEAD`. |
| 5 | **Subagent backend drop** | *"Execution backend unavailable"* mid-workflow | Long PR flows lose shell access; use file logs + parent agent Read tool. |
| 6 | **Windows path redirects** | `Out-File` to `%TEMP%` or UNC fails; log file not created | Redirect logs **inside WSL** to `.agent-local/` (via `agent-run.sh`). |

**Not the main cause here:** sandbox blocking (allowlisted `wsl.exe` / git usually runs outside sandbox). GitHub API rate limits are separate from shell capture.

---

## Mandatory agent pattern (git / PR)

Do **not** rely on raw `wsl.exe … git status` stdout for multi-step flows.

```bash
# PR作成まで (logged)
wsl.exe -d Ubuntu bash -lc 'cd ~/workspace/SmartResearch-HQ && bash scripts/agent-git-pr-complete.sh'

# Any long script
wsl.exe -d Ubuntu bash -lc 'cd ~/workspace/SmartResearch-HQ && bash scripts/agent-run.sh -- bash scripts/ci-check.sh'
```

After every run, **Read**:

- `.agent-local/latest.log` — full log (PR URL, errors, git output; truncated each run)
- `.agent-local/latest.exit` — exit code

Probe when unsure:

```bash
bash scripts/agent-shell-probe.sh
```

---

## Why WSL `ls` / `git` does not see agent-written files

| Cause | Symptom | Fix |
|-------|---------|-----|
| **Folder opened from Windows UNC** (`\\wsl.localhost\...`) | Cursor shows files; WSL terminal on old branch or stale tree | **Command Palette → `WSL: Reopen Folder in WSL`** — path becomes `~/workspace/SmartResearch-HQ` |
| **`main` not pulled** after remote merge | `MISSING: docs/agents/engineering-principles.md` in ship preflight | WSL: `git fetch origin && git checkout main && git pull --ff-only origin main` |
| **Agent on wrong branch** | Files exist on `origin/main` but not in checkout | `git checkout main && git pull` |
| **Windows Git vs WSL Git** | Source Control phantom `M`, empty `git diff` in WSL | `.vscode/settings.json` → `git.path` = WSL git (already set in this repo) |

Quick check: `bash scripts/verify-wsl-workspace.sh` — lists missing paths and fix commands.

---

## Fix order

1. **Command Palette** → `WSL: Reopen Folder in WSL` (workspace path must be `~/workspace/...`, not only `\\wsl.localhost\...`).
2. **Cursor Settings** → Agents → enable **Legacy Terminal Tool** → restart Cursor.
3. Use **`agent-run.sh`** or **`agent-git-pr-complete.sh`** (not bare piped git).
4. If stdout is still empty, **Read** `.agent-local/latest.log` (written inside WSL, gitignored).
5. Verify success without trusting Shell: `.git/logs/HEAD` or `.agent-local/latest.exit`.

**Do not** use PowerShell `git -C \\wsl.localhost\...` for commits or pushes.

### Do not create ad-hoc repo-root log files

When Shell stdout is empty, some agents wrote **one-off** scripts that `tee` to names like `_fix-main.log` or `.ship-closeout.log`. Those scripts were **never committed**; the logs are stale debug output only.

| Wrong (creates clutter) | Right |
|-------------------------|-------|
| `LOG="$(pwd)/_fix-main.log"` + `tee` in a new script | `bash scripts/agent-run.sh -- …` |
| `.ship-closeout.log`, `.ship-*.log`, `*-log.txt` at repo root | `source scripts/agent-local-log.sh` → `.agent-local/name.log` |
| Append forever to repo-root logs | `agent-run.sh` → `.agent-local/latest.log` (truncate each run) |

Remove leftovers: `bash scripts/clean-agent-local-artifacts.sh` (repo-root junk; add `--all` to purge `.agent-local/` too)

See also: [agent-git-playbook.md](agent-git-playbook.md).

---

# Cursor エージェント Shell が空になるとき（WSL）

手元の WSL ターミナルは動くのに **エージェントの Shell だけ空** のときの手順。

## 根本原因（本リポジトリで確認済み）

| # | 原因 | 症状 | 理由 |
|---|------|------|------|
| 1 | **パイプ出力の取りこぼし** | `git status \| head` が Shell 上は空、ファイルリダイレクトは成功 | Windows 上の Cursor Shell が WSL の **パイプ stdout** をキャプチャできないことがある |
| 2 | **UNC と WSL の二重ビュー** | エディタにファイルがあるが WSL checkout が古い | `\\wsl.localhost\...` のまま開いている |
| 3 | **PowerShell + クォート** | 長い `wsl -lc '…'` が途中で壊れる | heredoc / ネスト引用を一行に詰めない |
| 4 | **終了コード不明** | *no exit status* | 空 stdout では成否が分からない → ログファイル必須 |
| 5 | **サブエージェント backend 停止** | *Execution backend unavailable* | 長時間フローはファイルログ + Read で確認 |
| 6 | **Windows 側リダイレクト** | `%TEMP%` や UNC への Out-File 失敗 | ログは WSL 内 `.agent-local/` へ |

## エージェント必須パターン（git / PR）

```bash
wsl.exe -d Ubuntu bash -lc 'cd ~/workspace/SmartResearch-HQ && bash scripts/agent-git-pr-complete.sh'
```

実行後は **`.agent-local/latest.log`** と **`.agent-local/latest.exit`** を Read する。

診断: `bash scripts/agent-shell-probe.sh`

## WSL でファイルが見えない理由

| 原因 | 症状 | 対処 |
|------|------|------|
| **Windows UNC でフォルダを開いている** | Cursor にはあるが WSL の checkout が古い | **`WSL: Reopen Folder in WSL`** |
| **リモート merge 後に pull していない** | ship preflight でファイル欠落 | `git fetch origin && git checkout main && git pull --ff-only origin main` |
| **作業ブランチが古い** | `origin/main` にだけ存在 | `git checkout main && git pull` |

確認: `bash scripts/verify-wsl-workspace.sh`

## 手順

1. **`WSL: Reopen Folder in WSL`**
2. **Legacy Terminal Tool** を ON → Cursor 再起動
3. **`agent-run.sh` / `agent-git-pr-complete.sh`** を使う（生の piped git に依存しない）
4. 出力が空なら **`.agent-local/latest.log`** を Read
5. `.git/logs/HEAD` / `.agent-local/latest.exit` で push/commit を確認

PowerShell の UNC 経由 `git` は使わない。

### リポジトリ直下に ad-hoc ログを作らない

Shell 出力が空のとき、エージェントが `_fix-main.log` や `.ship-closeout.log` へ `tee` する **一時スクリプト** を書いたことがある。スクリプトは **コミットされていない** — ログは古いデバッグ出力だけ。

| 避ける | 使う |
|--------|------|
| `LOG="$(pwd)/_fix-main.log"` 等 | `bash scripts/agent-run.sh -- …` |
| リポ直下の `.ship-*.log`, `*-log.txt` | `source scripts/agent-local-log.sh` → `.agent-local/` |
| `agent-cmd-output.txt` を無限 append | `agent-run.sh` → `.agent-local/latest.log`（実行ごと truncate） |

残っていれば: `bash scripts/clean-agent-local-artifacts.sh`（直下の junk のみ。`.agent-local/` も消すなら `--all`）
