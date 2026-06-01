#!/usr/bin/env bash
# Print git state for agents before commit/push/PR. Optional strict mode blocks ambiguity.
# Usage:
#   bash scripts/git-agent-context.sh           # report only (exit 0)
#   bash scripts/git-agent-context.sh --strict  # exit 1 on risky state
# Env:
#   GIT_AGENT_EXPECTED_BRANCH=feat/foo  override .git/agent-expected-branch

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

case "${1:-}" in
  pin)
    BR="$(git branch --show-current 2>/dev/null || true)"
    if [[ -z "$BR" || "$BR" == "main" || "$BR" == "master" ]]; then
      echo "ERROR: pin on a feature branch, not ${BR:-detached}" >&2
      exit 1
    fi
    printf '%s\n' "$BR" > .git/agent-expected-branch
    echo "Pinned expected branch: ${BR}"
    exit 0
    ;;
  clear)
    rm -f .git/agent-expected-branch
    echo "Cleared expected branch pin"
    exit 0
    ;;
esac

STRICT=0
if [[ "${1:-}" == "--strict" ]]; then
  STRICT=1
fi

EXPECTED="${GIT_AGENT_EXPECTED_BRANCH:-}"
if [[ -z "$EXPECTED" && -f .git/agent-expected-branch ]]; then
  EXPECTED="$(tr -d '\r\n' < .git/agent-expected-branch)"
fi

BASE="${GIT_PR_BASE:-main}"
BRANCH="$(git branch --show-current 2>/dev/null || true)"
DIRTY="$(git status --porcelain 2>/dev/null || true)"
MERGE=0
[[ -f .git/MERGE_HEAD ]] && MERGE=1

BLOCK=0
WARN=0

echo "=== Agent Git context ==="
echo "repo: ${ROOT}"
echo "branch: ${BRANCH:-(detached)}"
echo "base: origin/${BASE}"

if [[ -n "$EXPECTED" ]]; then
  echo "expected_branch: ${EXPECTED}"
  if [[ "$BRANCH" != "$EXPECTED" ]]; then
    echo "WARN: current branch differs from expected (agent may be on wrong task)"
    WARN=1
    if [[ "$STRICT" -eq 1 ]]; then
      BLOCK=1
    fi
  fi
else
  echo "expected_branch: (not set — run git-start-branch.sh or set GIT_AGENT_EXPECTED_BRANCH)"
fi

if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
  if [[ -n "$DIRTY" ]]; then
    echo "WARN: on ${BRANCH} with uncommitted changes — create a feature branch first"
    WARN=1
    BLOCK=1
  fi
fi

if [[ "$MERGE" -eq 1 ]]; then
  echo "WARN: merge in progress (.git/MERGE_HEAD) — finish or abort before new work"
  WARN=1
  BLOCK=1
fi

git fetch origin "$BASE" 2>/dev/null || true
if [[ -n "$BRANCH" && "$BRANCH" != "main" && "$BRANCH" != "master" ]]; then
  if git rev-parse "origin/${BASE}" >/dev/null 2>&1; then
    if git merge-base --is-ancestor "origin/${BASE}" HEAD 2>/dev/null; then
      echo "vs origin/${BASE}: includes latest base"
    else
      echo "WARN: behind origin/${BASE} — run git-pr-complete.sh or git-merge-main-safe.sh"
      WARN=1
    fi
  fi
fi

if [[ -n "$DIRTY" ]]; then
  COUNT="$(printf '%s\n' "$DIRTY" | grep -c . || true)"
  echo "uncommitted: ${COUNT} path(s)"
  printf '%s\n' "$DIRTY" | head -12
  if [[ "$COUNT" -gt 12 ]]; then
    echo "... (+$((COUNT - 12)) more)"
  fi
else
  echo "uncommitted: none"
fi

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1 && [[ -n "$BRANCH" ]]; then
  # shellcheck source=gh-pr-branch.sh
  source "$ROOT/scripts/gh-pr-branch.sh"
  PR_URL="$(gh_pr_url_for_branch "$BRANCH" 2>/dev/null || true)"
  if [[ -n "$PR_URL" ]]; then
    echo "open_pr_this_branch: ${PR_URL}"
  else
    echo "open_pr_this_branch: (none)"
  fi
  echo "other_open_prs (max 5):"
  gh pr list --state open --limit 5 --json number,headRefName,title \
    -q '.[] | "#\(.number) \(.headRefName) — \(.title)"' 2>/dev/null || echo "  (unable to list)"
fi

echo "=== end context ==="

if [[ "$BLOCK" -eq 1 ]]; then
  echo "STOP: fix context above before commit/push/PR (or explain branch switch to user)." >&2
  exit 1
fi

if [[ "$WARN" -eq 1 ]]; then
  echo "NOTE: warnings present — confirm task/branch with user if unsure." >&2
fi

exit 0
