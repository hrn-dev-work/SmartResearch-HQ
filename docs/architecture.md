# SmartResearch-HQ — システムアーキテクチャ

## 1. 概要

越境EC（Shopee 等）の商品リサーチ・名寄せを自動化するシステム。  
**二刀流戦略**（表：ポートフォリオ版 / 裏：完全稼働版）で同一コードベースを運用する。

| 層 | 技術 | 役割 |
|----|------|------|
| フロントエンド | Next.js 16, TypeScript, Tailwind CSS | ダッシュボード・レビュー UI（Human-in-the-loop） |
| API | FastAPI (Python 3.11+) | REST + ジョブ投入、ステータス配信 |
| スクレイピング | Playwright (Python) | Shopee セラー SOLD 商品の抽出 |
| 候補マッチング | プラガブル（既定: Amazon タイトル検索） | Shopee 商品 → Amazon ASIN 候補（最大 N 件） |
| ジョブキュー | Redis + ARQ (または Celery) | 非同期スクレイプ・マッチングの待ち行列 |
| 永続化 | PostgreSQL | リサーチ履歴・レビュー結果 |

## 2. 論理アーキテクチャ

```
┌─────────────────────────────────────────────────────────────────┐
│                     Next.js (Browser)                            │
│  Dashboard ──► Research Start    Review UI ──► Confirm ASIN     │
└────────────────────────────┬────────────────────────────────────┘
                             │ REST / SSE (進捗)
┌────────────────────────────▼────────────────────────────────────┐
│                    FastAPI (API Gateway)                         │
│  /research  /review  /health                                     │
│  ┌──────────────┐  APP_MODE=portfolio → MockService             │
│  │ Job Enqueue  │  APP_MODE=production → Real pipeline          │
│  └──────┬───────┘                                                │
└─────────┼────────────────────────────────────────────────────────┘
          │
    ┌─────▼─────┐     ┌──────────────┐     ┌─────────────────┐
    │   Redis   │────►│   Workers    │────►│  PostgreSQL     │
    │   Queue   │     │ Scrape→Match │     │  research_jobs  │
    └───────────┘     └──────┬───────┘     └─────────────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
        Playwright    CandidateMatcher   Google Sheets
        (Shopee)      (see §4)           (export)
```

## 3. 処理パイプライン（ステートマシン）

```
PENDING → SCRAPING → SCRAPE_FAILED (retry/DLQ)
       → AI_INFERENCE → AI_FAILED (retry/DLQ)
       → AWAITING_REVIEW → APPROVED → EXPORTED
                       → REJECTED
```

- **AI_INFERENCE**: 候補マッチング処理中（名称は後方互換のため維持。Gemini 専用ではない）。
- **SCRAPE_FAILED / AI_FAILED**: 指数バックオフでリトライ。上限超過でデッドレターキューへ。
- フロントエンドは `GET /research/{job_id}` または SSE で細かいステータスをポーリング。

## 4. 二刀流（表裏）の切り替え

| 設定 | 表（portfolio） | 裏（production） |
|------|-----------------|------------------|
| `APP_MODE` | `portfolio` | `production` |
| スクレイピング | 固定フィクスチャ JSON | Playwright 実装 |
| 候補マッチング | モック候補 3 件 | `MATCHING_PROVIDER` で切替（§4.1） |
| スプレッドシート | ログのみ | Google Sheets API |
| 公開 | フロント + docs + Mock | Private リポジトリ全体 |

### 4.1 候補マッチングプロバイダ（`MATCHING_PROVIDER`）

| 値 | 方式 | 優先度 |
|----|------|--------|
| `amazon_search`（**既定**） | Shopee タイトル → Amazon キーワード検索 | Phase 2 本線 |
| `none` | 候補自動生成なし。レビュアーが手動で ASIN 確定 | クォータゼロ |
| `gemini` | 画像+テキストのマルチモーダル推論 + Structured JSON | 任意・後置き |

実装: `backend/app/services/matching/` — `get_candidate_matcher()` が DI 入口。

### 4.2 Amazon 検索 API 選定（Phase 2 前の決定）

**採用: Amazon Product Advertising API 5.0（PA-API）** を第一候補とする。

| 観点 | PA-API 5.0 | SP-API Catalog |
|------|------------|----------------|
| 用途 | キーワード検索 → 商品メタ取得 | カタログ参照・出品者向け |
| 本プロジェクトとの適合 | タイトル検索に直結 | 検索用途にはオーバースペック |
| 前提 | Associates アカウント + API 資格 | Seller Central |

環境変数（`.env.example` 参照）: `AMAZON_PAAPI_ACCESS_KEY`, `AMAZON_PAAPI_SECRET_KEY`, `AMAZON_PAAPI_PARTNER_TAG`, `AMAZON_PAAPI_REGION`.

PA-API が使えない場合のフォールバック: `MATCHING_PROVIDER=none` で手動 ASIN レビュー。

## 5. ディレクトリ構成

```
SmartResearch-HQ/
├── docs/                 # 設計ドキュメント（本ディレクトリ）
├── frontend/             # Next.js
├── backend/              # FastAPI + workers
│   └── app/services/
│       ├── matching/     # 候補マッチング（プラガブル）
│       ├── scraper/      # Playwright
│       ├── mock/         # portfolio 用
│       └── spreadsheet/  # Sheets export
├── docker-compose.yml    # PostgreSQL, Redis（production 検証用）
└── scripts/              # bootstrap-local.sh, start-dev.sh
```

## 6. 非機能要件

- **堅牢性**: CAPTCHA / IP ブロック時はワーカー単位で失敗し、API は 500 で全体を落とさない。
- **マッチング Ops**: 候補は固定スキーマ（asin, url, title, confidence）。失敗時は `AI_FAILED` + 監査ログ。
- **セキュリティ**: API キー・サービスアカウントは環境変数のみ。表版リポジトリに本番キーを含めない。
- **スクレイピング運用**: Shopee ToS・robots を遵守。リクエスト間隔を設け、ブロック時はジョブ単位で失敗（[requirements.md §3.2](./requirements.md)）。
- **portfolio 公開時**: 認証なしのため Phase 4 デプロイ前に CORS 本番 origin 固定・レート制限を検討。

## 7. ローカル開発

| モード | 必要なもの |
|--------|------------|
| **portfolio（既定）** | backend venv + frontend のみ。Postgres / Redis 不要 |
| **production 検証** | `docker compose up -d postgres redis` + ワーカー |

初回: `bash scripts/bootstrap-local.sh`（`.env` / `frontend/.env.local` を `.example` から生成）。

## 8. デプロイ想定（将来）

- フロント: Vercel
- API / Worker: Railway / Fly.io / ECS
- DB: マネージド PostgreSQL
- Redis: Upstash 等
