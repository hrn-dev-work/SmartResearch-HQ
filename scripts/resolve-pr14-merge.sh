#!/usr/bin/env bash
# Resolve PR #14 merge conflicts: keep main i18n UI + both agent-push presets.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ ! -f .git/MERGE_HEAD ]]; then
  echo "No merge in progress. Run: git checkout docs/portfolio-deploy-live && git merge origin/main" >&2
  exit 1
fi

# main (#15 i18n UI) wins for frontend conflicts
git checkout --theirs \
  frontend/src/app/globals.css \
  frontend/src/app/page.tsx \
  frontend/src/components/AboutDemoDialog.tsx \
  frontend/src/lib/ui-classes.ts

# agent-push: keep both presets (portfolio from branch, production from main)
cat > scripts/agent-push.sh <<'SCRIPT'
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
#   production-local-setup — production local docs + start script
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
    production-local-setup)
      BRANCH="feat/production-local-setup"
      MSG_FILE="$ROOT/scripts/commit-msgs/feat-production-local-setup.txt"
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
SCRIPT
chmod +x scripts/agent-push.sh

git add \
  frontend/src/app/globals.css \
  frontend/src/app/page.tsx \
  frontend/src/components/AboutDemoDialog.tsx \
  frontend/src/lib/ui-classes.ts \
  scripts/agent-push.sh

if [[ -n "$(git diff --name-only --diff-filter=U)" ]]; then
  echo "Still unmerged:" >&2
  git diff --name-only --diff-filter=U >&2
  exit 1
fi

git commit -F - <<'EOF'
merge main: keep i18n UI from main and deploy presets on agent-push

Resolve PR #14 conflicts with main (#15): adopt main frontend i18n/layout,
combine portfolio-docs-deploy and production-local-setup in agent-push.sh.

---

PR #14 と main (#15) のコンフリクト解消。フロント i18n は main を採用、
agent-push は両 preset を維持。
EOF

bash scripts/ci-check.sh
git push origin docs/portfolio-deploy-live
bash scripts/sync-pr-body.sh docs/portfolio-deploy-live main || true

echo "PR_URL=$(gh pr view 14 --json url -q .url 2>/dev/null || gh pr list --head docs/portfolio-deploy-live --json url -q '.[0].url')"
echo "MERGEABLE=$(gh pr view 14 --json mergeable -q .mergeable 2>/dev/null || echo unknown)"
