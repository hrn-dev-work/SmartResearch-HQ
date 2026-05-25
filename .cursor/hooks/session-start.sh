#!/usr/bin/env bash
# Injects session defaults for SmartResearch-HQ agents (sessionStart hook).
set -euo pipefail

read -r _input || true

python3 <<'PY'
import json

context = """SmartResearch-HQ — セッション既定（ユーザーは意識不要）

- 入口: AGENTS.md → docs/wbs-roadmap.md で未完了タスクを1件だけ
- 仕様: docs/requirements.md + docs/design.md（矛盾時 design 優先）
- ローカル: APP_MODE=portfolio（Mock）。MATCHING_PROVIDER=amazon_search。Gemini/DB/Redis は明示時のみ
- シェル: WSL Ubuntu bash（Git Bash 禁止）— .cursor/skills/wsl-local-dev/SKILL.md
- 常時ルール: agent-efficiency / implementation-core / testing-istqb / security-git / de-ai-ui / implementation-retrospective
- UI: .cursor/rules/de-ai-ui.mdc + docs/design.md §2
- Git・コミット: .cursor/rules/security-git.mdc + .cursor/skills/commit-pr-style/SKILL.md
- スキル一覧: docs/prompt-templates.md
- 実装後: afterFileEdit → stop フックがコード変更後に反省会を自動起票（implementation-retrospective.mdc）
- 変更は最小 diff。広いリポジトリ探索・依頼外リファクタ禁止
- 進捗: Phase 1 完了。Phase 2〜 は wbs-roadmap の未完了行を参照
"""

print(json.dumps({"additional_context": context}, ensure_ascii=False))
PY
