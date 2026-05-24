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
