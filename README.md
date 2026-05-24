# SmartResearch-HQ

越境EC（Shopee 等）の商品リサーチ・名寄せを **スクレイピング + 候補マッチング + Human-in-the-loop** で自動化するシステム。

| 版 | 目的 | 本リポジトリ |
|----|------|-------------|
| **表**（ポートフォリオ） | 転職・提案用デモ | Mock API + フロント + 設計 docs |
| **裏**（完全版） | 実運用・副収入 | Private で Playwright / マッチング / Sheets |

## 技術スタック

- **Frontend**: Next.js 16, TypeScript, Tailwind CSS
- **Backend**: FastAPI, Pydantic v2
- **Infra**: PostgreSQL 16, Redis 7 (docker compose — production 検証用)
- **Phase 2+**: Playwright, Amazon PA-API タイトル検索, Google Sheets（Gemini は任意）

## 開発環境

### 前提

| 項目 | バージョン / 備考 |
|------|-------------------|
| OS | **WSL Ubuntu**（Windows 上）。Git Bash + UNC パスは venv 破損の原因になるため使わない |
| Python | **3.12**（`python3.12-venv` パッケージが必要な場合あり） |
| Node.js | **20 LTS**（CI と同じ。`npm ci` / `npm run dev`） |
| エディタ | **Cursor** または VS Code。リポジトリを WSL 側 `~/workspace/SmartResearch-HQ` で開く |
| Docker | 任意。`production` 検証（Postgres / Redis）時のみ |

### 初回セットアップ

```bash
# WSL Ubuntu
sudo apt update
sudo apt install -y python3.12-venv git

# Node 20（未インストール時 — nvm 例）
# curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
# nvm install 20

cd ~/workspace/SmartResearch-HQ
bash scripts/bootstrap-local.sh   # .env / backend venv / frontend npm ci
```

### Cursor / VS Code 拡張機能

ワークスペースを開くと **推奨拡張のインストール** を促されます（`.vscode/extensions.json`）。

| 拡張 | 用途 |
|------|------|
| **Ruff** | Python lint / format（保存時に自動修正） |
| **Python** + **Pylance** | 型補完・venv 連携 |
| **ESLint** | TypeScript / React の lint |
| **Tailwind CSS IntelliSense** | Tailwind クラス補完 |
| **Docker** | `docker-compose.yml` 編集・コンテナ操作 |
| **GitHub Actions** | CI ワークフローのシンタックスハイライト |
| **EditorConfig** | インデント・改行コードの統一 |

手動で入れる場合: Cursor の拡張機能タブで上記名を検索するか、コマンドパレット → **Extensions: Show Recommended Extensions**。

保存時の format / lint は `.vscode/settings.json` で有効（Python → Ruff、TS/TSX → ESLint）。

### 品質チェック（push 前）

```bash
# GitHub CI と同内容（backend: Ruff + pytest / frontend: ESLint + build）
bash scripts/ci-check.sh
```

CI の概要: [docs/git-workflow.md §5.1](docs/git-workflow.md)（個人用メモ: [`docs/local/`](docs/local/) は gitignore）

### 任意ツール

| ツール | 用途 |
|--------|------|
| [GitHub CLI (`gh`)](https://cli.github.com/) | PR 作成・CI 状態確認 |
| Docker Compose | Phase 2 production 検証 |

---

## クイックスタート（portfolio / Mock）

**Postgres / Redis は不要**です。

```bash
# 初回: .env と venv を自動セットアップ
bash scripts/bootstrap-local.sh
```

### バックエンド

```bash
cd backend
source .venv/bin/activate
uvicorn app.main:app --reload --port 8000
```

`GET http://localhost:8000/api/v1/health` → `{ "status": "ok", "mode": "portfolio", "matching_provider": "amazon_search" }`

### フロントエンド

```bash
cd frontend
npm run dev
```

http://localhost:3000 → Shopee URL を入力 → レビュー画面で Amazon 候補を選択。

### production 検証（任意）

```bash
cp .env.example .env   # 未作成時
docker compose up -d postgres redis
```

## リポジトリ構成

```
├── docs/           # 設計ドキュメント
│   └── local/      # ローカル専用（gitignore。README のみ tracked）
├── frontend/       # Next.js ダッシュボード & レビュー UI
├── backend/        # FastAPI（portfolio 時は Mock サービス）
│   └── app/services/matching/  # 候補マッチング（プラガブル）
├── docker-compose.yml
└── scripts/        # bootstrap-local.sh, start-dev.sh
```

## ドキュメント

- [プロジェクト計画書](docs/プロジェクト計画書.md) — 概要・戦略
- [要件定義](docs/requirements.md)
- [設計（UI・MVP）](docs/design.md)
- [アーキテクチャ](docs/architecture.md)
- [DB スキーマ](docs/database-schema.md)
- [API 仕様](docs/api-specification.md)
- [WBS・ロードマップ](docs/wbs-roadmap.md)
- [Git ブランチ運用](docs/git-workflow.md) — 作業ブランチ → PR → CI → マージ
- [ローカル専用メモ](docs/local/README.md) — 個人用・反省会ログ（`docs/local/` 内は gitignore）

## 環境変数

| 変数 | 説明 |
|------|------|
| `APP_MODE` | `portfolio`（Mock） / `production` |
| `MATCHING_PROVIDER` | `amazon_search`（既定） / `none` / `gemini`（任意） |
| `AMAZON_PAAPI_*` | PA-API 5.0（production / `amazon_search` 時） |
| `GEMINI_API_KEY` | `gemini` 利用時のみ（コミット禁止） |
| `NEXT_PUBLIC_API_URL` | フロント → API（既定: `http://localhost:8000/api/v1`） |

`.env` は gitignore 対象。初回は `cp .env.example .env` または `bootstrap-local.sh`。

## ロードマップ

- **Phase 1** ✅ 設計 + モノレポ + docs 整合
- **Phase 2** Playwright / Amazon 検索 / Sheets / ワーカー
- **Phase 3** 進捗 SSE・Redis 本接続（UI は一部先行完了）
- **Phase 4** 公開デモ・Vercel デプロイ

## ライセンス

Private / Portfolio 用途に応じて運用。表版ではスクレイピング回避・プロンプト等のコア実装は非公開。
