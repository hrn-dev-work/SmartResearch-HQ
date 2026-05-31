#!/usr/bin/env bash
# Validate tracked public markdown: English block → --- → Japanese block (full mirror).
# Usage: bash scripts/validate-public-docs.sh [file.md ...]
# Exit 0 if all OK, 1 if any file fails.

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

mapfile -t FILES < <(
  if [[ $# -gt 0 ]]; then
    printf '%s\n' "$@"
  else
    {
      [[ -f README.md ]] && echo README.md
      [[ -f frontend/README.md ]] && echo frontend/README.md
      find docs -maxdepth 1 -name '*.md' -type f 2>/dev/null | grep -v frontend-structure | grep -v production-local-setup | sort
    }
  fi
)

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "No public markdown files to validate." >&2
  exit 0
fi

python3 - "$ROOT" "${FILES[@]}" <<'PY'
import re
import sys
from pathlib import Path

ROOT = Path(sys.argv[1])
paths = [Path(p) for p in sys.argv[2:]]

JA = re.compile(r"[\u3040-\u9fff\u30a0-\u30ff]")
H1 = re.compile(r"^#\s+")


def validate(path: Path) -> list[str]:
    rel = path.relative_to(ROOT) if path.is_absolute() else path
    if not path.is_file():
        return [f"{rel}: file not found"]

    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines:
        return [f"{rel}: empty file"]

    h1_lines = [i for i, line in enumerate(lines) if H1.match(line)]
    if not h1_lines:
        return [f"{rel}: missing # heading"]

    first_h1 = h1_lines[0]
    if JA.search(lines[first_h1]):
        return [f"{rel}: first # heading must be English (line {first_h1 + 1})"]

    ja_h1 = next((i for i in h1_lines if JA.search(lines[i])), None)
    if ja_h1 is None:
        return [
            f"{rel}: missing Japanese # heading block "
            "(add full JA section after ---, not a short footer)"
        ]

    if not any(line.strip() == "---" for line in lines[:ja_h1]):
        return [f"{rel}: need a horizontal rule '---' before Japanese block (before line {ja_h1 + 1})"]

    en_lines = ja_h1
    ja_lines = len(lines) - ja_h1
    min_en, min_ja = (8, 8) if len(lines) < 80 else (15, 15)

    if en_lines < min_en:
        return [f"{rel}: English block too short ({en_lines} lines before JA heading; min {min_en})"]
    if ja_lines < min_ja:
        return [
            f"{rel}: Japanese block too short ({ja_lines} lines) — "
            "mirror the English structure, not a bullet footer only"
        ]

    return []


errors: list[str] = []
for p in paths:
    if not p.is_absolute():
        p = ROOT / p
    errors.extend(validate(p))

if errors:
    print("Public docs validation FAILED:", file=sys.stderr)
    for e in errors:
        print(f"  - {e}", file=sys.stderr)
    print("Convention: docs/doc-conventions.md", file=sys.stderr)
    print("Fix: English sections first, then ---, then full Japanese mirror.", file=sys.stderr)
    sys.exit(1)

print(f"Public docs validation OK ({len(paths)} files)")
PY
