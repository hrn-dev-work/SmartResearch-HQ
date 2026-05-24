# SmartResearch-HQ — Agent playbook

エージェント向けの入口。ユーザーは短い依頼でよい。

**詳細資料（背景・ファイル一覧・セットアップ）**: [`docs/local/cursor-agent-efficiency.md`](docs/local/cursor-agent-efficiency.md)（`docs/local/` は gitignore）

## いまのフェーズ

- **Phase 1** ✅ 完了（docs + モノレポ骨組み）
- **Phase 2** ✅ 完了（2.2c Gemini は任意・未着手）
- **Phase 3** 進行中 → タスクは `docs/wbs-roadmap.md` の **未完了 1 件だけ** 着手

## 読む順（実装前）

1. `docs/wbs-roadmap.md` — 今回のスコープ
2. `docs/プロジェクト計画書.md` — 概要・二刀流・マッチング方針
3. `docs/requirements.md` + `docs/design.md`
4. 必要なら `docs/architecture.md` / `docs/api-specification.md`

実装後の振り返りログ: [`docs/local/implementation-retrospective.md`](docs/local/implementation-retrospective.md)

## ローカル既定

| 項目 | 値 |
|------|-----|
| `APP_MODE` | `portfolio`（Mock） |
| `MATCHING_PROVIDER` | `amazon_search`（Gemini は明示時のみ） |
| API | `http://localhost:8000/api/v1` |
| UI | `http://localhost:3000` |
| シェル | WSL Ubuntu（`.cursor/skills/wsl-local-dev/SKILL.md`） |

起動: `bash scripts/bootstrap-local.sh` または skill 内の 2 ターミナル手順。

## Cursor ルール（自動適用）

| ルール | いつ |
|--------|------|
| `.cursor/rules/agent-efficiency.mdc` | 常時 |
| `.cursor/rules/implementation-core.mdc` | 常時（DDD・命名・疎結合・原則） |
| `.cursor/rules/testing-istqb.mdc` | 常時（ISTQB 準拠テスト方針） |
| `.cursor/rules/security-git.mdc` | 常時（秘密情報・Git） |
| `.cursor/rules/implementation-retrospective.mdc` | 常時（実装後反省会） |
| `.cursor/rules/de-ai-ui.mdc` | 常時（UI コピー・レイアウト） |
| `.cursor/rules/backend-python.mdc` | `backend/**` |
| `.cursor/rules/frontend-work.mdc` | `frontend/**` |
| `.cursor/rules/docs-editing.mdc` | `docs/**` |

索引: [`.cursor/rules/README.md`](.cursor/rules/README.md)

## スキル

[`docs/prompt-templates.md`](docs/prompt-templates.md) — スキル名・内容・指示文（`scripts/sync-skill-prompt-table.py` で自動生成。Skill 変更時: `.cursor/rules/skills-table-sync.mdc`）

## Git（ブランチ運用）

[`docs/git-workflow.md`](docs/git-workflow.md) — **phase1 直コミット禁止**。ブランチ → PR → **CI green** → squash マージ。

- ローカル CI: `bash scripts/ci-check.sh`
- 作業開始: `bash scripts/git-start-branch.sh feat/wbs-x-y-説明`

## フロントのみ

Next.js 16 の注意: `frontend/AGENTS.md`

## ユーザー依頼の例

- ✅ 「WBS 2.3 用ブランチを切って、コミット・push・PR まで」
- ✅ 「レビュー画面で候補を confidence 降順に」（→ ブランチ上で実装）
- ✅ 「WBS 2.2 の Amazon 検索マッチャの骨組み」
- ⚠️ 「全部実装して」→ WBS の 1 ID に分割してから（フックが促す場合あり）
