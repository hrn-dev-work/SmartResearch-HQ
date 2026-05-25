#!/usr/bin/env bash
set -euo pipefail
cd /home/haruna/workspace/SmartResearch-HQ

python3 <<'PY'
import json
from pathlib import Path

body2 = """## Summary

**Merge order:** Step 2 of 3 — `phase2` → `main` _(マージ順 2/3。#1 の前にマージ)_

- WBS 2.3: Google Sheets export for production _(本番 Sheets エクスポート)_
- WBS 3.4: Job progress polling on review screen _(レビュー画面の進捗ポーリング)_
- CI / agent workflow scaffolding _(CI・エージェント運用の骨組み)_
- Ruff format pass _(Ruff フォーマット)_

- style(backend): apply ruff format
- feat(frontend): add job progress polling on review screen (WBS 3.4)
- chore: add Cursor rules, hooks, CI, and agent workflow
- fix(api): return SPREADSHEET_CONFIG on Sheets export misconfiguration
- feat(spreadsheet): Google Sheets export for production (WBS 2.3)

## Test plan

- [ ] `bash scripts/ci-check.sh`
- [ ] CI `backend` / `frontend` green

## Related

- Branch: `phase2` · WBS: 2.3, 3.4 · Blocks: #1
- Merge sequence: phase1 on `main` → **this PR (#2)** → PR #1 _(phase1 は `main` より先行、`phase1` ブランチは固定スナップショット)_
"""

body1 = """## Summary

**Merge order:** Step 3 of 3 — merge after PR #2 _(マージ順 3/3。#2 マージ後)_

Phase 3 increment on top of `phase2`:

- WBS 3.5: Redis health check on `/health` _(本番 Redis ヘルスチェック)_
- WBS 3.6: Manual ASIN input on review screen _(手動 ASIN 入力 UI)_
- Dev environment: EditorConfig, VS Code/Cursor, README _(開発環境整備)_
- Auto PR on push _(push 時の自動 PR)_

- feat(backend): Redis health check for production (WBS 3.5)
- feat(review): manual ASIN input on review screen (WBS 3.6)
- chore: add editor config, dev environment docs, and ruff fixes
- chore: auto-create PR on push

## Test plan

- [ ] `bash scripts/ci-check.sh`
- [ ] CI green
- [ ] Portfolio: manual ASIN on item with no candidates _(候補なしで手動 ASIN)_

## Related

- Branch: `phase3` · WBS: 3.5, 3.6 · Depends on: #2
- Final target: `main` _(base は `main`。#2 マージ後に diff が phase3 分に絞られる)_
"""

body3 = """## Summary

- Compact bilingual PR template: 3 sections, English primary _(PR 本文を 3 セクションに整理)_
- Japanese inline as _(…)_ on the same line _(日本語は同行の _(…)_ で記載)_
- `render-pr-body.sh` for manual/auto PR; drop duplicate EN/JA sections _(重複見出しを廃止)_

## Test plan

- [ ] `bash scripts/ci-check.sh`
- [ ] CI green
- [ ] `bash scripts/render-pr-body.sh manual feat/example` prints compact scaffold

## Related

- Branch: `chore/pr-body-bilingual-template`
"""

Path("/tmp/pr2.json").write_text(json.dumps({"body": body2}))
Path("/tmp/pr1.json").write_text(json.dumps({"body": body1}))
Path("/tmp/pr3.json").write_text(
    json.dumps(
        {
            "title": "chore(git): compact bilingual PR template",
            "body": body3,
        }
    )
)
PY

gh api repos/hrn-dev-work/SmartResearch-HQ/pulls/2 -X PATCH --input /tmp/pr2.json
gh api repos/hrn-dev-work/SmartResearch-HQ/pulls/1 -X PATCH --input /tmp/pr1.json
gh api repos/hrn-dev-work/SmartResearch-HQ/pulls/3 -X PATCH --input /tmp/pr3.json

echo "Updated PR #1, #2, #3 to compact bilingual format"
