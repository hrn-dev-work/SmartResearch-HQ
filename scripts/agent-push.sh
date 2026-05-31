#!/usr/bin/env bash
# Agent-friendly git push: branch, safe-add, commit, push. No heredoc on CLI.
#
# Usage:
#   bash scripts/agent-push.sh portfolio-docs-deploy
#   bash scripts/agent-push.sh --branch feat/foo --subject "feat(scope): message"
#   bash scripts/agent-push.sh --branch feat/foo --msg-file path/to/msg.txt
#
# Presets:
#   portfolio-docs-deploy — README + deployment-guide + .gitignore (demo URL publish)
#
# Logs via agent-run if invoked as: bash scripts/agent-run.sh -- bash scripts/agent-push.sh ...

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PRESET="${1:-}"
BRANCH=""
SUBJECT=""
MSG_FILE=""

if [[ -n "$PRESET" && "$PRESET" != --* ]]; then
  case "$PRESET" in
    portfolio-docs-deploy)
      BRANCH="docs/portfolio-deploy-live"
      MSG_FILE="$ROOT/scripts/commit-msgs/portfolio-docs-deploy.txt"
      ;;
    *)
      echo "Unknown preset: $PRESET" >&2
      exit 2
      ;;
  esac
  shift || true
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch) BRANCH="$2"; shift 2 ;;
    --subject) SUBJECT="$2"; shift 2 ;;
    --msg-file) MSG_FILE="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$BRANCH" ]]; then
  echo "Usage: bash scripts/agent-push.sh <preset>|--branch NAME (--subject S|--msg-file F)" >&2
  exit 2
fi

CURRENT="$(git branch --show-current)"
if [[ "$CURRENT" == "main" || "$CURRENT" == "master" ]]; then
  git fetch origin
  git checkout -b "$BRANCH"
elif [[ "$CURRENT" != "$BRANCH" ]]; then
  git checkout "$BRANCH" 2>/dev/null || git checkout -b "$BRANCH"
fi

bash "$ROOT/scripts/git-add-safe.sh"
# Preset commit messages must stay tracked (may match a broad local exclude).
if [[ -d "$ROOT/scripts/commit-msgs" ]]; then
  git add -f scripts/commit-msgs/*.txt 2>/dev/null || true
fi

if git diff --cached --quiet; then
  echo "Nothing staged to commit."
  exit 0
fi

echo "=== staged ==="
git diff --cached --name-only

if [[ -n "$MSG_FILE" ]]; then
  if [[ ! -f "$MSG_FILE" ]]; then
    echo "Missing msg file: $MSG_FILE" >&2
    exit 1
  fi
  git commit -F "$MSG_FILE"
elif [[ -n "$SUBJECT" ]]; then
  git commit -m "$SUBJECT"
else
  echo "Provide --subject or --msg-file (or use a preset with msg file)." >&2
  exit 2
fi

bash "$ROOT/scripts/git-ship.sh" push

echo "branch: $(git branch --show-current)"
echo "hash: $(git rev-parse --short HEAD)"
git status -sb
