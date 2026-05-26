# エージェント / Cursor セットアップ（公開リポジトリ）

このリポジトリの **GitHub 上の clone（表・お客様向け）には `.cursor/` を含めない**。

| 層 | 内容 | リポジトリ |
|----|------|------------|
| **表** | アプリ・設計 docs・CI | 本リポジトリ（公開） |
| **裏** | Cursor rules / skills / hooks | **ローカルのみ**（`.cursor/`、各自で用意） |

## 公開 clone でエージェントが読むもの

1. [`AGENTS.md`](../AGENTS.md) — 入口
2. [`docs/git-workflow.md`](git-workflow.md) — ブランチ・コミット・PR・WSL の git
3. [`docs/wbs-roadmap.md`](wbs-roadmap.md) — スコープ
4. 仕様: `requirements.md` / `design.md` ほか `docs/` 直下

## ローカルで Cursor を使う人（開発者向け）

1. WSL Ubuntu で `~/workspace/SmartResearch-HQ` を開く（UNC 直開きは phantom diff の原因）
2. `.vscode/settings.json` の `git.path` を WSL の git に（§8 [`git-workflow.md`](git-workflow.md)）
3. `bash scripts/install-git-hooks.sh`
4. **`.cursor/`** は gitignore。別マシンではバックアップからコピーするか、[`docs/local/README.md`](local/README.md) のメモに沿って再作成する（`docs/local/*` も clone には含まれない）

## コミット漏れ防止（リポジトリ共通）

| ユーザー依頼 | エージェント |
|--------------|--------------|
| **プッシュまで** / push | 未コミットがあれば commit → push |
| **PR作成まで** / PR まで | commit → push → PR |
| **コミットだけ** | commit のみ |
| 実装のみ | 勝手に commit しない。終了時に WSL で `git status` を報告 |

詳細: [`docs/git-workflow.md`](git-workflow.md) §6・§8。
