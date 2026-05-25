#!/usr/bin/env python3
"""Sync docs/wbs-roadmap.md task status and README phase checkboxes from repo artifacts."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ROADMAP = ROOT / "docs" / "wbs-roadmap.md"
README = ROOT / "README.md"

TABLE_ROW = re.compile(
    r"^\| (?P<id>[0-9]+(?:\.[0-9]+)?[a-z]?) \| (?P<task>[^|]+) \| (?P<artifact>[^|]+) \| (?P<status>[^|]+) \|$"
)
BACKTICK = re.compile(r"`([^`]+)`")
DONE_MARK = "✅"
PENDING_MARKS = ("未着手", "未")

# Optional tasks — do not block phase completion in README.
OPTIONAL_IDS = frozenset({"2.2c", "4.3"})

# Extra checks when the artifact cell has no filesystem path.
CUSTOM_CHECKS: dict[str, list[str]] = {
    "2.2c": ["backend/app/services/matching/gemini.py"],
    "3.4": ["frontend/src/hooks/useJobProgress.ts"],
    "3.5": [
        "backend/app/core/redis.py",
        "backend/app/api/routes/health.py:ping_redis",
    ],
    "3.6": [
        "frontend/src/lib/asin.ts",
        "frontend/src/app/review/[jobId]/page.tsx:manualAsin",
    ],
    "4.1": ["backend/app/services/mock/fixtures.py"],
}


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def path_exists(rel: str) -> bool:
    p = ROOT / rel.strip("/ ")
    return p.exists()


def check_spec(spec: str) -> bool:
    if ":" in spec:
        rel, needle = spec.split(":", 1)
        p = ROOT / rel.strip("/ ")
        return p.is_file() and needle in read_text(p)
    return path_exists(spec)


def artifact_paths(artifact_cell: str) -> list[str]:
    paths = BACKTICK.findall(artifact_cell)
    return [p for p in paths if "/" in p or p.endswith(".py") or p.endswith(".md")]


def task_done(task_id: str, artifact_cell: str) -> bool:
    checks: list[str] = []
    checks.extend(artifact_paths(artifact_cell))
    checks.extend(CUSTOM_CHECKS.get(task_id, []))

    if not checks:
        return False

    return all(check_spec(spec) for spec in checks)


def status_label(task_id: str, artifact_cell: str, current: str) -> str:
    current = current.strip()
    if DONE_MARK in current:
        return current
    if not task_done(task_id, artifact_cell):
        return current
    if "初版" in artifact_cell or task_id.startswith(("2.", "3.")):
        return "✅ 初版" if task_id not in {"3.1", "3.2", "3.3"} else "✅ 先行完了"
    return "✅"


def sync_roadmap(content: str) -> tuple[str, int]:
    changes = 0
    out: list[str] = []

    for line in content.splitlines():
        m = TABLE_ROW.match(line)
        if not m:
            out.append(line)
            continue

        new_status = status_label(m["id"], m["artifact"], m["status"])
        if new_status != m["status"].strip():
            changes += 1
        out.append(
            f"| {m['id']} | {m['task'].strip()} | {m['artifact'].strip()} | {new_status} |"
        )

    return "\n".join(out) + ("\n" if content.endswith("\n") else ""), changes


def collect_task_states(content: str) -> dict[str, bool]:
    states: dict[str, bool] = {}
    for line in content.splitlines():
        m = TABLE_ROW.match(line)
        if not m:
            continue
        states[m["id"]] = DONE_MARK in status_label(m["id"], m["artifact"], m["status"])
    return states


def phase_complete(phase: int, states: dict[str, bool]) -> bool:
    prefix = f"{phase}."
    ids = [tid for tid in states if tid.startswith(prefix)]
    if not ids:
        return False
    for tid in ids:
        if tid in OPTIONAL_IDS:
            continue
        if not states.get(tid, False):
            return False
    return True


PHASE_LINE = re.compile(r"^- \[[ xX]\] \*\*Phase (\d)\*\*")


def sync_readme_phases(roadmap_content: str, readme_content: str) -> tuple[str, int]:
    states = collect_task_states(roadmap_content)
    changes = 0
    out: list[str] = []

    for line in readme_content.splitlines():
        m = PHASE_LINE.match(line)
        if not m:
            out.append(line)
            continue

        phase = int(m.group(1))
        mark = "x" if phase_complete(phase, states) else " "
        new_line = re.sub(r"^- \[[ xX]\]", f"- [{mark}]", line, count=1)
        if new_line != line:
            changes += 1
        out.append(new_line)

    return "\n".join(out) + ("\n" if readme_content.endswith("\n") else ""), changes


def main() -> int:
    parser = argparse.ArgumentParser(description="Sync WBS roadmap and README phase checkboxes")
    parser.add_argument("--check", action="store_true", help="Exit 1 if files would change")
    parser.add_argument("--quiet", action="store_true")
    args = parser.parse_args()

    if not ROADMAP.is_file():
        print(f"Missing {ROADMAP}", file=sys.stderr)
        return 1

    roadmap_raw = read_text(ROADMAP)
    roadmap_new, roadmap_changes = sync_roadmap(roadmap_raw)

    readme_changes = 0
    readme_new = readme_raw = read_text(README) if README.is_file() else ""
    if README.is_file():
        readme_new, readme_changes = sync_readme_phases(roadmap_new, readme_raw)

    total = roadmap_changes + readme_changes
    if total == 0:
        if not args.quiet:
            print("WBS roadmap: already up to date")
        return 0

    if args.check:
        print(f"WBS roadmap: {roadmap_changes} task(s), README: {readme_changes} phase line(s) would change")
        return 1

    ROADMAP.write_text(roadmap_new, encoding="utf-8")
    if README.is_file() and readme_changes:
        README.write_text(readme_new, encoding="utf-8")

    if not args.quiet:
        print(f"Updated wbs-roadmap.md ({roadmap_changes} task(s))")
        if readme_changes:
            print(f"Updated README.md ({readme_changes} phase line(s))")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
