# SmartResearch-HQ — Agent playbook

エージェント向けの入口。ユーザーは短い依頼でよい。

**詳細資料（背景・ファイル一覧・セットアップ）**: [`docs/cursor-agent-efficiency.md`](docs/cursor-agent-efficiency.md)

## いまのフェーズ

- **Phase 1** ✅ 完了（docs + モノレポ骨組み）
- **Phase 2〜** 進行中 → タスクは `docs/wbs-roadmap.md` の **未完了 1 件だけ** 着手

## 読む順（実装前）

1. `docs/wbs-roadmap.md` — 今回のスコープ
2. `docs/プロジェクト計画書.md` — 概要・二刀流・マッチング方針
3. `docs/requirements.md` + `docs/design.md`
4. 必要なら `docs/architecture.md` / `docs/api-specification.md`

実装後の振り返りログ: [`docs/implementation-retrospective.md`](docs/implementation-retrospective.md)

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

[`docs/git-workflow.md`](docs/git-workflow.md) — **main 直コミット禁止**。ブランチ → PR → **CI green** → squash マージ。

| 依頼 | スキル / コマンド |
|------|-------------------|
| **プッシュまで** | `commit-pr-style` → `bash scripts/git-ship.sh push` |
| **PR作成まで** | `commit-pr-style` → `bash scripts/git-ship.sh pr` |
| 作業開始 | `bash scripts/git-start-branch.sh feat/...` |
| ローカル CI | `bash scripts/ci-check.sh` |

push / PR 作成は **許可なく実行してよい**（`security-git.mdc`）。

**コミット漏れ防止**: 「プッシュまで」「PR作成まで」「コミットだけ」は commit の明示依頼（グローバル user rule より本リポジトリルール優先）。実装のみのセッション終了時は `git status` を報告。`stop` フックが未コミットを検知したら followup で促す。

**Cursor Source Control**: `.vscode/settings.json` の `git.path` は WSL の git（phantom `M` 抑制）。詳細は `docs/git-workflow.md` §8。

## フロントのみ

Next.js 16 の注意: `frontend/AGENTS.md`

## ユーザー依頼の例

- ✅ 「プッシュまでお願い」→ commit + push まで（PR は作らない）
- ✅ 「PR作成までお願い」→ commit + push + PR URL 報告
- ✅ 「WBS 2.3 用ブランチを切って、コミット・push・PR まで」
- ✅ 「レビュー画面で候補を confidence 降順に」（→ ブランチ上で実装）
- ✅ 「WBS 2.2 の Amazon 検索マッチャの骨組み」
- ⚠️ 「全部実装して」→ WBS の 1 ID に分割してから（フックが促す場合あり）
