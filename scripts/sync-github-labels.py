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
        print(f"ERROR: missing {LABELS}", file=sys.stderr)
        return 1

    try:
        subprocess.run(
            ["gh", "auth", "status"],
            check=True,
            capture_output=True,
            text=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        print(
            "ERROR: gh CLI not logged in. Run: gh auth login",
            file=sys.stderr,
        )
        return 1

    items = json.loads(LABELS.read_text(encoding="utf-8"))
    if not isinstance(items, list):
        print("ERROR: labels.json must be a JSON array", file=sys.stderr)
        return 1

    for item in items:
        name = item["name"]
        color = item["color"].lstrip("#")
        description = item.get("description", "")
        subprocess.run(
            [
                "gh",
                "label",
                "create",
                name,
                "--color",
                color,
                "--description",
                description,
                "--force",
            ],
            check=True,
        )
        print(f"OK  {name}")

    print(f"Synced {len(items)} labels from {LABELS}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
