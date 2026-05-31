#!/usr/bin/env bash
# Validate PR body: EN **Section** → --- → JA **Section**. Rejects legacy ## Summary.
# Usage:
#   bash scripts/validate-pr-body.sh <pr-number>
#   bash scripts/validate-pr-body.sh --stdin
#   bash scripts/validate-pr-body.sh --file path.md

set -euo pipefail

read_body() {
  case "${1:-}" in
    --stdin)
      cat
      ;;
    --file)
      [[ -n "${2:-}" && -f "$2" ]] || {
        echo "Usage: bash scripts/validate-pr-body.sh --file <path>" >&2
        exit 1
      }
      cat "$2"
      ;;
    '')
      echo "Usage: bash scripts/validate-pr-body.sh <pr-number>|--stdin|--file <path>" >&2
      exit 1
      ;;
    *)
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        gh pr view "$1" --json body -q .body
      else
        echo "Usage: bash scripts/validate-pr-body.sh <pr-number>|--stdin|--file <path>" >&2
        exit 1
      fi
      ;;
  esac
}

validate_body() {
  local body="$1"

  if [[ -z "$body" ]]; then
    echo "PR body is empty" >&2
    return 1
  fi

  if [[ "$body" == @/* ]] || [[ "$body" == @* ]]; then
    echo "body is a temp path ($body) — gh api -f body=@file bug; run: bash scripts/update-pr-body-from-file.sh <pr> <file>" >&2
    return 1
  fi

  if grep -q '^## Summary' <<<"$body"; then
    echo "legacy single-language format (## Summary) — use **Summary** EN block, ---, then JA block" >&2
    return 1
  fi

  if ! grep -qxF '---' <<<"$body"; then
    echo "missing horizontal rule '---' between English and Japanese blocks" >&2
    return 1
  fi

  local en_part ja_part
  en_part="$(awk 'BEGIN{p=1} /^---$/{p=0; next} p{print}' <<<"$body")"
  ja_part="$(awk 'BEGIN{p=0} /^---$/{p=1; next} p{print}' <<<"$body")"

  if [[ -z "$en_part" || -z "$ja_part" ]]; then
    echo "English or Japanese block is empty after '---'" >&2
    return 1
  fi

  local section
  for section in "Summary" "Commits" "Test plan" "Related"; do
    if ! grep -q "\*\*${section}\*\*" <<<"$en_part"; then
      echo "missing English **${section}** section" >&2
      return 1
    fi
  done

  for section in "概要 (Summary)" "コミット (Commits)" "テスト計画 (Test plan)" "関連 (Related)"; do
    if ! grep -qF "**${section}**" <<<"$ja_part"; then
      echo "missing Japanese **${section}** section" >&2
      return 1
    fi
  done

  return 0
}

BODY="$(read_body "$@")"
if validate_body "$BODY"; then
  echo "PR body validation OK"
else
  exit 1
fi
