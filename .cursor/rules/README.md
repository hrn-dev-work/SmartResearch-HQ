# SmartResearch-HQ — Cursor Rules

| ファイル | 適用 | 内容 |
|----------|------|------|
| `agent-efficiency.mdc` | 毎セッション | WBS 1 タスク、Mock 既定、最小 diff、探索抑制 |
| `implementation-core.mdc` | 毎セッション | DDD・命名・疎結合・可読性・DRY/YAGNI 等 |
| `testing-istqb.mdc` | 毎セッション | ISTQB 準拠のテストレベル・結合/システム方針 |
| `security-git.mdc` | 毎セッション | 秘密情報・Git・env |
| `implementation-retrospective.mdc` | 毎セッション | 実装後反省会・ルール更新手順 |
| `de-ai-ui.mdc` | 毎セッション | 脱AI UI・コピー |
| `backend-python.mdc` | `backend/**` | Mock / マッチング / サービス置き場 |
| `frontend-work.mdc` | `frontend/**` | Next.js 16、api 層、UI 参照 |
| `docs-editing.mdc` | `docs/**` | 正本優先順位、重複禁止 |
| `skills-table-sync.mdc` | `.cursor/skills/**` | Skill 変更後に `prompt-templates.md` を同期 |

## グローバル User Rules との関係

- **参照**: `~/.cursor/rules/global-balanced-defaults.mdc`（可読性・最小変更・安全）
- **優先**: 本リポジトリの `.cursor/rules/*.mdc` + `docs/` + `AGENTS.md`

作業手順: リポジトリ直下の [`AGENTS.md`](../../AGENTS.md)
