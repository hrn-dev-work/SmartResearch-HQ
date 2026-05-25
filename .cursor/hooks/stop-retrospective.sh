#!/usr/bin/env bash
# After code edits + agent completion: warn on uncommitted changes, then retrospective (stop).
set -euo pipefail

input=$(cat)

printf '%s' "$input" | python3 <<'PY'
import json
import subprocess
import sys
from pathlib import Path

try:
    payload = json.load(sys.stdin)
except json.JSONDecodeError:
    print("{}")
    raise SystemExit(0)

status = payload.get("status", "")
loop_count = int(payload.get("loop_count", 0))
marker = Path(".cursor/retrospective/.session-edited")

out: dict = {}

if status != "completed" or loop_count != 0 or not marker.is_file():
    print(json.dumps(out, ensure_ascii=False))
    raise SystemExit(0)

parts: list[str] = []

porcelain = ""
try:
    r = subprocess.run(
        ["git", "status", "--porcelain"],
        capture_output=True,
        text=True,
        timeout=15,
        check=False,
    )
    if r.returncode == 0:
        porcelain = (r.stdout or "").strip()
except (OSError, subprocess.TimeoutExpired):
    porcelain = ""

if porcelain:
    lines = porcelain.splitlines()
    preview = "\n".join(lines[:12])
    if len(lines) > 12:
        preview += f"\n... (+{len(lines) - 12} more)"
    parts.append(
        "【自動・コミット漏れ候補】実装コードを編集したが作業ツリーに未コミットの変更があります。"
        "WSL で git status / git diff --stat を確認してください。"
        "ユーザーが「プッシュまで」「PR作成まで」「コミットだけ」と言っていれば commit-pr-style で直ちに commit してください。"
        "実装のみの依頼なら、最終報告に未コミット一覧を載せ、ユーザーにプッシュまでを促してください。\n"
        f"```\n{preview}\n```"
    )

parts.append(
    "【自動・実装反省会】今回のコード変更について "
    ".cursor/rules/implementation-retrospective.mdc の手順で反省会を実施してください。"
    "docs/implementation-retrospective.md に追記し、再発防止に効く改善のみ "
    ".cursor/rules/*.mdc を最小更新してください。"
    "完了したら「反省会完了」と1行で報告してください。"
    "（ユーザーがスキップを明示している場合のみ省略可）"
)

out["followup_message"] = "\n\n".join(parts)

try:
    marker.unlink()
except OSError:
    pass

print(json.dumps(out, ensure_ascii=False))
PY

exit 0
