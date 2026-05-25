#!/usr/bin/env bash
# After code edits + agent completion, auto-submit implementation retrospective prompt (stop).
set -euo pipefail

read -r _input || true

python3 <<'PY'
import json, sys
from pathlib import Path

try:
    payload = json.load(sys.stdin)
except json.JSONDecodeError:
    print("{}")
    sys.exit(0)

status = payload.get("status", "")
loop_count = int(payload.get("loop_count", 0))
marker = Path(".cursor/retrospective/.session-edited")

out: dict = {}

if status == "completed" and loop_count == 0 and marker.is_file():
    out["followup_message"] = (
        "【自動・実装反省会】今回のコード変更について "
        ".cursor/rules/implementation-retrospective.mdc の手順で反省会を実施してください。"
        "docs/implementation-retrospective.md に追記し、再発防止に効く改善のみ "
        ".cursor/rules/*.mdc を最小更新してください。"
        "完了したら「反省会完了」と1行で報告してください。"
        "（ユーザーがスキップを明示している場合のみ省略可）"
    )
    try:
        marker.unlink()
    except OSError:
        pass

print(json.dumps(out, ensure_ascii=False))
PY

exit 0
