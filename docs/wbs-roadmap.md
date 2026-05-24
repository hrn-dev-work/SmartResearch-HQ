# WBS・開発ロードマップ

想定総工数: **30〜40 時間**（AI 駆動開発前提）

## Phase 1: 要件定義・設計 ✅

| ID | タスク | 成果物 | 状態 |
|----|--------|--------|------|
| 1.1 | アーキテクチャ詳細化 | `docs/architecture.md` | ✅ |
| 1.2 | DB スキーマ設計 | `docs/database-schema.md` | ✅ |
| 1.3 | API I/O 定義 | `docs/api-specification.md` | ✅ |
| 1.4 | WBS 整理 | 本ドキュメント | ✅ |
| 1.5 | モノレポ骨組み | frontend/, backend/, docker-compose | ✅ |
| 1.6 | プロジェクト計画書・方針統一 | `docs/プロジェクト計画書.md` 他 docs 整合 | ✅ |

Phase 1 完了条件: docs 間の用語・マッチング方針・API パスが一致していること。

## Phase 2: コアロジック（裏版） ✅

| ID | タスク | 成果物 | 状態 |
|----|--------|--------|------|
| 2.1 | Playwright Shopee クローラー | `backend/app/services/scraper/` | ✅ 初版 |
| 2.2 | 候補マッチング（Amazon PA-API タイトル検索） | `backend/app/services/matching/` | ✅ 初版 |
| 2.2b | 手動 ASIN decide API + DB | review route, `review_decisions.manual_asin` | ✅ |
| 2.2c | Gemini マルチモーダル（任意） | `matching/gemini.py` | 任意・未着手 |
| 2.3 | Google Sheets 連携 | `backend/app/services/spreadsheet/` | ✅ 初版 |
| 2.4 | ARQ ワーカー + リトライ/DLQ | `backend/app/workers/` | ✅ 初版（enqueue + worker） |
| 2.5 | Alembic マイグレーション | `backend/alembic/` | ✅ |
| 2.6 | CLI エントリポイント | `python -m app.cli` | ✅ |

### Phase 2 ローカル検証（M2）

```bash
# 1. インフラ
docker compose up -d postgres redis

# 2. 依存関係 + Playwright ブラウザ
cd backend && source .venv/bin/activate
pip install -r requirements.txt
playwright install chromium

# 3. DB マイグレーション
python -m app.cli migrate

# 4. スクレイプのみ試す
python -m app.cli scrape --url "https://shopee.sg/..." --limit 5

# 5. フルパイプライン（.env で APP_MODE=production, PA-API キー設定）
python -m app.cli run --url "https://shopee.sg/..." --limit 5

# 6. ワーカー（別ターミナル、production API 利用時）
arq app.workers.settings.WorkerSettings
```

## Phase 3: UI / API（共通） — 進行中

| ID | タスク | 成果物 | 状態 |
|----|--------|--------|------|
| 3.1 | ダッシュボード UI | `frontend/src/app/page.tsx` | ✅ 先行完了 |
| 3.2 | レビュー UI | `frontend/src/app/review/[jobId]/` | ✅ 先行完了 |
| 3.3 | API クライアント + 型 | `frontend/src/lib/api.ts` | ✅ 先行完了 |
| 3.4 | ジョブ進捗ポーリング/SSE | hooks + API | ✅ MVP ポーリング |
| 3.5 | FastAPI ↔ Redis 本接続 | docker-compose 起動検証 | ✅ 初版（health `redis`） |
| 3.6 | 手動 ASIN 入力 UI | レビュー画面 §design 3.3 | 未着手（Phase 2 API 後） |

## Phase 4: ポートフォリオ化（表版）

| ID | タスク | 成果物 | 工数目安 |
|----|--------|--------|----------|
| 4.1 | Mock API 完成度向上 | `MockResearchService` | 2h |
| 4.2 | README・スクリーンショット | ルート README | 1h |
| 4.3 | デモ動画（Loom 等） | 外部 | 2h |
| 4.4 | Vercel デプロイ + CORS / レート制限 | 公開 URL | 2h |

## マイルストーン

```
M1: フロントから Mock リサーチ完了（portfolio）              ← 到達済み
    起動: bash scripts/bootstrap-local.sh → uvicorn + npm run dev
M2: CLI で 1 セラー実スクレイプ + amazon_search
M3: レビュー → Sheets 出力 E2E
M4: 公開 GitHub + デモ URL
```

## ローカル起動（portfolio）

Postgres / Redis **不要**。`.env` は `bootstrap-local.sh` が `.env.example` から生成。

```bash
bash scripts/bootstrap-local.sh
# ターミナル1: backend uvicorn :8000
# ターミナル2: frontend npm run dev :3000
```
