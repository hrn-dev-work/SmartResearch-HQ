#!/usr/bin/env bash
# Suggest an English PR title (Conventional Commits). Never copies Japanese commit subjects.
# Usage: bash scripts/render-pr-title.sh [base-branch] [head-branch]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BASE="${1:-main}"
BRANCH="${2:-$(git branch --show-current)}"

commit_count() {
  git rev-list --count "origin/${BASE}..HEAD" 2>/dev/null ||
    git rev-list --count "${BASE}..HEAD" 2>/dev/null ||
    echo 0
}

latest_subject() {
  git log "origin/${BASE}..HEAD" --format=%s -1 2>/dev/null ||
    git log "${BASE}..HEAD" --format=%s -1 2>/dev/null ||
    true
}

is_english_subject() {
  local subject="$1"
  [[ -n "$subject" ]] && [[ ! "$subject" =~ [ぁ-んァ-ン一-龥] ]]
}

title_from_branch() {
  local branch="$1"
  local type slug rest

  type="${branch%%/*}"
  rest="${branch#*/}"
  slug="${rest//-/ }"

  case "$type" in
    feat) echo "feat: ${slug}" ;;
    fix) echo "fix: ${slug}" ;;
    docs) echo "docs: ${slug}" ;;
    chore) echo "chore: ${slug}" ;;
    refactor) echo "refactor: ${slug}" ;;
    test) echo "test: ${slug}" ;;
    spike) echo "spike: ${slug}" ;;
    *) echo "chore: merge ${branch} into ${BASE}" ;;
  esac
}

COMMIT_COUNT="$(commit_count)"

if [[ "$BRANCH" =~ ^phase3$ ]]; then
  echo "Phase 3: Redis health + manual ASIN + dev setup (WBS 3.5–3.6)"
  exit 0
fi

if [[ "$BRANCH" =~ ^phase([0-9]+)$ ]]; then
  echo "Phase ${BASH_REMATCH[1]}: (edit English summary before merge)"
  exit 0
fi

if [[ "$COMMIT_COUNT" -le 1 ]]; then
  SUBJECT="$(latest_subject)"
  if is_english_subject "$SUBJECT"; then
    echo "$SUBJECT"
    exit 0
  fi
fi

title_from_branch "$BRANCH"
