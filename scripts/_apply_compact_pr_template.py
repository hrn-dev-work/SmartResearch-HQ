#!/usr/bin/env python3
"""One-off: write compact PR template files (EN primary, JA inline)."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

FILES = {
    ".github/PULL_REQUEST_TEMPLATE.md": """## Summary

- What changed _(変更内容)_

## Test plan

- [ ] `bash scripts/ci-check.sh`
- [ ] CI `backend` / `frontend` green

## Related

<!-- English keywords for GitHub (`Closes`, `Depends on`, etc.). Delete unused lines. -->
- Branch: `feat/...`
- WBS: x.y
- Issue: Closes #
""",
    "scripts/render-pr-body.sh": """#!/usr/bin/env bash
# Render PR body (manual scaffold or auto after push).
# Usage:
#   bash scripts/render-pr-body.sh manual [branch]
#   bash scripts/render-pr-body.sh auto <branch> [base]

set -euo pipefail

MODE="${1:-manual}"
BRANCH="${2:-feat/...}"
BASE="${3:-main}"

render_manual() {
  cat <<EOF
## Summary

- What changed _(変更内容)_

## Test plan

- [ ] \\`bash scripts/ci-check.sh\\`
- [ ] CI \\`backend\\` / \\`frontend\\` green

## Related

<!-- English keywords for GitHub. Delete unused lines. -->
- Branch: \\`${BRANCH}\\`
- WBS: x.y
- Issue: Closes #
EOF
}

render_auto() {
  local commits
  commits="$(git log "origin/${BASE}..HEAD" --format='- %s' 2>/dev/null || git log "${BASE}..HEAD" --format='- %s' 2>/dev/null || true)"
  if [[ -z "$commits" ]]; then
    commits="- (no commits ahead of ${BASE})"
  fi

  cat <<EOF
## Summary

- Auto-created on push to \\`${BRANCH}\\` — fill in before merge _(push 後に自動作成。マージ前に追記)_

${commits}

## Test plan

- [ ] \\`bash scripts/ci-check.sh\\`
- [ ] CI \\`backend\\` / \\`frontend\\` green

## Related

- Branch: \\`${BRANCH}\\`
EOF
}

case "$MODE" in
  manual) render_manual ;;
  auto) render_auto ;;
  *)
    echo "Usage: bash scripts/render-pr-body.sh manual [branch]" >&2
    echo "       bash scripts/render-pr-body.sh auto <branch> [base]" >&2
    exit 1
    ;;
esac
""",
}

for rel, content in FILES.items():
    path = ROOT / rel
    path.write_text(content, encoding="utf-8")
    if rel.endswith(".sh"):
        path.chmod(0o755)
    print(f"wrote {rel}")
