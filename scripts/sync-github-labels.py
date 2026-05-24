#!/usr/bin/env python3
"""Create or update GitHub labels from .github/labels.json (requires gh CLI)."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LABELS = ROOT / ".github" / "labels.json"


def main() -> int:
    if not LABELS.is_file():
        print(f"SKIP: missing {LABELS}", file=sys.stderr)
        return 0

    try:
        subprocess.run(["gh", "auth", "status"], check=True, capture_output=True, text=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("SKIP: gh CLI not logged in", file=sys.stderr)
        return 0

    items = json.loads(LABELS.read_text(encoding="utf-8"))
    for item in items:
        subprocess.run(
            [
                "gh",
                "label",
                "create",
                item["name"],
                "--color",
                item["color"].lstrip("#"),
                "--description",
                item.get("description", ""),
                "--force",
            ],
            check=True,
        )
        print(f"OK  {item['name']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
