#!/usr/bin/env bash
# Validate Architecture Decision Records under docs/adr/.
# Usage: bash scripts/validate-adrs.sh [docs/adr/NNNN-*.md ...]
# Exit 0 if all OK, 1 if any file fails.

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

mapfile -t FILES < <(
  if [[ $# -gt 0 ]]; then
    printf '%s\n' "$@"
  else
    find docs/adr -maxdepth 1 -name '[0-9][0-9][0-9][0-9]-*.md' ! -name '0000-*' -type f | sort
  fi
)

python3 - "$ROOT" "${FILES[@]}" <<'PY'
import re
import sys
from pathlib import Path

ROOT = Path(sys.argv[1])
paths = [Path(p) for p in sys.argv[2:]]


def resolve(path: Path) -> Path:
    return path if path.is_absolute() else ROOT / path


REQUIRED_SECTIONS = (
    "## Context",
    "## Decision",
    "## Consequences",
    "## Alternatives considered",
)
JA = re.compile(r"[\u3040-\u9fff\u30a0-\u30ff]")
ADR_FILE = re.compile(r"^docs/adr/(\d{4})-.+\.md$")
README = ROOT / "docs/adr/README.md"


def validate(path: Path) -> list[str]:
    rel = path.relative_to(ROOT)
    errors: list[str] = []

    if not path.is_file():
        return [f"{rel}: file not found"]

    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()

    if not lines:
        return [f"{rel}: empty file"]

    if rel.name == "0000-template.md":
        for section in REQUIRED_SECTIONS:
            if section not in text:
                errors.append(f"{rel}: template missing section {section!r}")
        return errors

    for section in REQUIRED_SECTIONS:
        if section not in text:
            errors.append(f"{rel}: missing required section {section!r}")

    h1_lines = [i for i, line in enumerate(lines) if line.startswith("# ")]
    if h1_lines and JA.search(lines[h1_lines[0]]):
        errors.append(f"{rel}: first # heading must be English (ADR convention)")

    if any(line.strip() == "---" for line in lines):
        errors.append(
            f"{rel}: language-boundary '---' is not allowed in ADRs "
            "(English-only; see docs/adr/README.md)"
        )

    if JA.search(text):
        errors.append(
            f"{rel}: Japanese characters found — ADRs are English-only; "
            "use docs/agents/ or bilingual docs/*.md for JA mirrors"
        )

    return errors


errors: list[str] = []
indexed_ids: set[str] = set()

if README.is_file():
    readme = README.read_text(encoding="utf-8")
    for match in re.finditer(r"\[(\d{4})\]\(\./(\d{4}-[^)]+\.md)\)", readme):
        indexed_ids.add(match.group(1))
else:
    errors.append("docs/adr/README.md: file not found")

for p in paths:
    p = resolve(p)
    rel = p.relative_to(ROOT).as_posix()
    if not ADR_FILE.match(rel):
        errors.append(f"{rel}: ADR files must match docs/adr/NNNN-short-title.md")
        continue
    errors.extend(validate(p))

adr_ids = sorted(
    {
        ADR_FILE.match(resolve(p).relative_to(ROOT).as_posix()).group(1)
        for p in paths
        if resolve(p).is_file()
        and (m := ADR_FILE.match(resolve(p).relative_to(ROOT).as_posix()))
        and m.group(1) != "0000"
    }
)

for adr_id in adr_ids:
    if adr_id not in indexed_ids:
        errors.append(f"docs/adr/README.md: missing index row for ADR {adr_id}")

for adr_id in sorted(indexed_ids):
    if adr_id not in adr_ids and adr_id != "0000":
        errors.append(f"docs/adr/README.md: index lists ADR {adr_id} but file is missing")

if errors:
    print("ADR validation FAILED:", file=sys.stderr)
    for e in errors:
        print(f"  - {e}", file=sys.stderr)
    print("Convention: docs/adr/README.md", file=sys.stderr)
    sys.exit(1)

print(f"ADR validation OK ({len(paths)} files)")
PY
