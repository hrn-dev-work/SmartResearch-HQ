#!/usr/bin/env bash
# Commit only WSL/Cursor workspace settings (no docs/agents or adr staged).
# Usage: bash scripts/commit-wsl-settings-only.sh
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ -f .git/MERGE_HEAD ]]; then
  echo "Aborting unfinished merge (MERGE_HEAD)..."
  git merge --abort
fi

git reset HEAD

FILES=(
  .vscode/settings.json
  .vscode/extensions.json
  docs/agent-shell-fix.md
  scripts/verify-wsl-workspace.sh
  scripts/commit-wsl-settings-only.sh
)

for f in "${FILES[@]}"; do
  [[ -f "$f" ]] || { echo "ERROR: missing $f" >&2; exit 1; }
done

chmod +x scripts/verify-wsl-workspace.sh

git add "${FILES[@]}"

if git diff --cached --quiet; then
  echo "Nothing to commit (files match HEAD?)."
  exit 0
fi

echo "Staged:"
git diff --cached --name-only

bash scripts/validate-public-docs.sh docs/agent-shell-fix.md

git commit -F - <<'EOF'
chore: WSL-first Cursor settings and workspace verify script

Point git/terminal at WSL, add verify-wsl-workspace.sh, document UNC vs WSL desync.

---

Cursor を WSL 優先にし、UNC/WSL 不一致の確認スクリプトと docs を追加。
EOF

echo "Committed: $(git rev-parse --short HEAD)"
