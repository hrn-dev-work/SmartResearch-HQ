# SmartResearch-HQ — Agent playbook

エージェント向けの入口（**公開 clone 用**）。Cursor の rules / skills は **`.cursor/` に置き、リポジトリには含めない**（[`docs/agent-setup.md`](docs/agent-setup.md)）。

## いまのフェーズ

- **Phase 1** ✅ 完了（docs + モノレポ骨組み）
- **Phase 2〜** 進行中 → タスクは `docs/wbs-roadmap.md` の **未完了 1 件だけ** 着手

## 読む順（実装前）

1. `docs/wbs-roadmap.md` — 今回のスコープ
2. `docs/プロジェクト計画書.md` — 概要・二刀流・マッチング方針
3. `docs/requirements.md` + `docs/design.md`
4. 必要なら `docs/architecture.md` / `docs/api-specification.md`

## ローカル既定

| 項目 | 値 |
|------|-----|
| `APP_MODE` | `portfolio`（Mock） |
| `MATCHING_PROVIDER` | `amazon_search`（Gemini は明示時のみ） |
| API | `http://localhost:8000/api/v1` |
| UI | `http://localhost:3000` |
| シェル | **WSL Ubuntu bash**（Git Bash + UNC 禁止） |

起動: `bash scripts/bootstrap-local.sh`

## Git（ブランチ運用）

[`docs/git-workflow.md`](docs/git-workflow.md) — **main 直コミット禁止**。ブランチ → PR → **CI green** → squash マージ。

| 依頼 | コマンド |
|------|----------|
| **プッシュまで** | 未コミットを commit → `bash scripts/git-ship.sh push` |
| **PR作成まで** | 上記 + `bash scripts/git-ship.sh pr` |
| 作業開始 | `bash scripts/git-start-branch.sh feat/...` |
| ローカル CI | `bash scripts/ci-check.sh` |

**コミット漏れ防止**: 「プッシュまで」「PR作成まで」「コミットだけ」は commit の明示依頼。実装のみのセッション終了時は WSL で `git status` を報告。

**Source Control**: `.vscode/settings.json` の `git.path` は WSL の git（[`git-workflow.md` §8](docs/git-workflow.md)）。

## フロントのみ

Next.js 16 の注意: `frontend/AGENTS.md`

## ユーザー依頼の例

- ✅ 「プッシュまでお願い」→ commit + push まで（PR は作らない）
- ✅ 「PR作成までお願い」→ commit + push + PR URL 報告
- ✅ 「WBS 2.3 用ブランチを切って、コミット・push・PR まで」
- ⚠️ 「全部実装して」→ WBS の 1 ID に分割してから
