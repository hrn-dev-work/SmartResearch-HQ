#!/usr/bin/env bash
# Warn when frontend-structure docs are staged without architecture.md cross-link in the same commit.
# Non-blocking (exit 0). Called from git-add-safe.sh after staging.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

mapfile -t STAGED < <(git diff --cached --name-only 2>/dev/null || true)
[[ ${#STAGED[@]} -eq 0 ]] && exit 0

has_structure_doc=0
has_arch=0
for f in "${STAGED[@]}"; do
  case "$f" in
    docs/frontend-structure.md | docs/frontend-structure-guide.md)
      has_structure_doc=1
      ;;
    docs/architecture.md)
      has_arch=1
      ;;
  esac
done

[[ "$has_structure_doc" -eq 0 ]] && exit 0

if [[ "$has_arch" -eq 0 ]]; then
  echo "WARN: staged frontend-structure docs but docs/architecture.md is not staged." >&2
  echo "      Add architecture.md §5 link in the same commit (PR #32 follow-up lesson)." >&2
  echo "      See docs/agent-git-playbook.md — Docs bundle checklist." >&2
  exit 0
fi

if ! git diff --cached -- docs/architecture.md | grep -qE 'frontend-structure-guide|frontend-structure\.md'; then
  echo "WARN: docs/architecture.md is staged but the diff lacks frontend-structure cross-links." >&2
  echo "      Update §5 Directory layout / ディレクトリ構成 frontend/ line." >&2
  exit 0
fi

exit 0
