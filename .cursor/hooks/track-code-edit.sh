#!/usr/bin/env bash
# Marks session when Agent edits implementation code (afterFileEdit).
set -euo pipefail

read -r _input || true

python3 <<'PY'
import json, re, sys
from pathlib import Path

try:
    payload = json.load(sys.stdin)
except json.JSONDecodeError:
    sys.exit(0)

file_path = payload.get("file_path", "")
if not file_path:
    sys.exit(0)

# Implementation paths (posix + windows separators)
CODE = (
    r"(/|\\)(backend|frontend/src|src|scripts)(/|\\)",
    r"\.(py|ts|tsx|js|jsx)$",
)
SKIP = (
    r"(/|\\)docs(/|\\)",
    r"(/|\\)\.cursor(/|\\)rules(/|\\)",
    r"(/|\\)\.cursor(/|\\)hooks(/|\\)",
    r"(/|\\)node_modules(/|\\)",
    r"(/|\\)\.venv(/|\\)",
)

norm = file_path.replace("\\", "/")
if any(re.search(p, norm) for p in SKIP):
    sys.exit(0)
if not (re.search(CODE[0], norm) and re.search(CODE[1], norm, re.I)):
    sys.exit(0)

marker_dir = Path(".cursor/retrospective")
marker_dir.mkdir(parents=True, exist_ok=True)
(marker_dir / ".session-edited").write_text(norm, encoding="utf-8")
PY

exit 0
