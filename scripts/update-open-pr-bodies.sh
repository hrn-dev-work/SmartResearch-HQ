#!/usr/bin/env bash
# Rewrite open PR bodies to EN --- JA format (currently PR #1).
# Usage: bash scripts/update-open-pr-bodies.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CI="$(bash "$ROOT/scripts/pr-ci-checkbox.sh" 1)"
TMP="$(mktemp)"

python3 - "$CI" >"$TMP" <<'PY'
import json
import sys

ci = sys.argv[1]
body1 = f"""## Summary

**Merge order:** Step 3 of 3 — after PR #2 (merged)

Phase 3 increment on top of `phase2`:

- WBS 3.5: Redis health check on `/health`
- WBS 3.6: Manual ASIN input on review screen
- Dev environment: EditorConfig, VS Code/Cursor, README
- Auto PR on push and CI checkbox sync

- feat(backend): Redis health check for production (WBS 3.5)
- feat(review): manual ASIN input on review screen (WBS 3.6)
- chore: add editor config, dev environment docs, and ruff fixes
- chore: auto-create PR on push

---

**マージ順:** 3/3 — PR #2（マージ済み）の後

`phase2` 上の Phase 3 増分:

- WBS 3.5: 本番 `/health` の Redis ヘルスチェック
- WBS 3.6: レビュー画面の手動 ASIN 入力 UI
- 開発環境: EditorConfig、VS Code/Cursor、README
- push 時の自動 PR と CI チェックボックス同期

- feat(backend): Redis health check for production (WBS 3.5)
- feat(review): manual ASIN input on review screen (WBS 3.6)
- chore: add editor config, dev environment docs, and ruff fixes
- chore: auto-create PR on push

## Test plan

- [{ci}] `bash scripts/ci-check.sh` passes
- [{ci}] CI `backend` / `frontend` green
- [ ] Portfolio: manual ASIN on item with no candidates

---

- [{ci}] `bash scripts/ci-check.sh` が通る
- [{ci}] CI `backend` / `frontend` green
- [ ] 候補なしジョブで手動 ASIN UI を確認

## Related

- Branch: `phase3` · WBS: 3.5, 3.6 · After: #2 (merged)
- Final target: `main`

---

- ブランチ: `phase3` · WBS: 3.5, 3.6 · 前提: #2 マージ済み
- マージ先: `main`
"""

print(json.dumps({
    "title": "Phase 3: Redis health + manual ASIN + dev setup (WBS 3.5–3.6)",
    "body": body1,
}))
PY

gh api repos/hrn-dev-work/SmartResearch-HQ/pulls/1 -X PATCH --input "$TMP"
rm -f "$TMP"
echo "Updated PR #1 title and body (EN --- JA format)"
