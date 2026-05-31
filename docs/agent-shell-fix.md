# Cursor agent shell — empty output (WSL)

When **your WSL terminal works** but the **Cursor agent Shell returns nothing**, use this checklist before asking the user to run commands manually.

---

## Fix order

1. **Command Palette** → `WSL: Reopen Folder in WSL` (workspace path must be `~/workspace/...`, not only `\\wsl.localhost\...`).
2. **Cursor Settings** → Agents → enable **Legacy Terminal Tool** → restart Cursor.
3. Agent commands must use:

```bash
wsl.exe -d Ubuntu bash -lc 'cd ~/workspace/SmartResearch-HQ && git status; echo EXIT:$?'
```

4. If stdout is still empty, write proof to a tracked file and **Read** it:

```bash
wsl.exe -d Ubuntu bash -lc 'cd ~/workspace/SmartResearch-HQ && git status > agent-cmd-output.txt 2>&1; git rev-parse --short HEAD >> agent-cmd-output.txt'
```

5. Verify success without trusting empty Shell: read `.git/logs/HEAD` or `agent-cmd-output.txt`.

**Do not** use PowerShell `git -C \\wsl.localhost\...` for commits or pushes.

See also: [agent-git-playbook.md](agent-git-playbook.md).

---

---

# Cursor エージェント Shell が空になるとき（WSL）

手元の WSL ターミナルは動くのに **エージェントの Shell だけ空** のときの手順。

## 手順

1. **`WSL: Reopen Folder in WSL`**
2. **Legacy Terminal Tool** を ON → Cursor 再起動
3. コマンドは `wsl.exe -d Ubuntu bash -lc 'cd ~/workspace/SmartResearch-HQ && …'`
4. 出力が空なら `agent-cmd-output.txt` にリダイレクトして Read
5. `.git/logs/HEAD` で push/commit の成否を確認

PowerShell の UNC 経由 `git` は使わない。
