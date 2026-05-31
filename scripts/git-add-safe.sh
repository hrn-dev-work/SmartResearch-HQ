#!/usr/bin/env bash
# Stage modified/new files; skip paths matched by .gitignore (e.g. AGENTS.md).
# Usage: bash scripts/git-add-safe.sh [path...]

set -euo pipefail
cd "$(dirname "$0")/.."

if [[ $# -gt 0 ]]; then
  for path in "$@"; do
    if git check-ignore -q "$path" 2>/dev/null; then
      echo "skip (gitignore): $path" >&2
    else
      git add -- "$path"
    fi
  done
  exit 0
fi

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  xy="${line:0:2}"
  path="${line:3}"
  if [[ "$xy" == "??" || "$xy" == " M" || "$xy" == "M " || "$xy" == " A" || "$xy" == "A " ]]; then
    if git check-ignore -q "$path" 2>/dev/null; then
      echo "skip (gitignore): $path" >&2
    else
      git add -- "$path"
    fi
  fi
done < <(git status --porcelain)
