# WBS and development roadmap

Estimated effort: **30–40 hours** (AI-assisted development).

> **Status column auto-updates**: When artifact paths exist in the repo, `scripts/sync-wbs-roadmap.py` marks ✅ (`pre-commit` / `ci-check.sh`). README Phase checkboxes stay in sync.

## Phase 1: Requirements and design ✅

| ID | Task | Deliverable | Status |
|----|------|-------------|--------|
| 1.1 | Architecture detail | `docs/architecture.md` | ✅ |
| 1.2 | DB schema | `docs/database-schema.md` | ✅ |
| 1.3 | API I/O | `docs/api-specification.md` | ✅ |
| 1.4 | WBS | This document | ✅ |
| 1.5 | Monorepo skeleton | frontend/, backend/, docker-compose | ✅ |
| 1.6 | Project plan alignment | `docs/プロジェクト計画書.md` + doc consistency | ✅ |

Phase 1 done when: terminology, matching policy, and API paths align across docs.

## Phase 2: Core logic (production) — ✅ Done

| ID | Task | Deliverable | Status |
|----|------|-------------|--------|
| 2.1 | Playwright Shopee crawler | `backend/app/services/scraper/` | ✅ |
| 2.2 | Candidate matching (PA-API) | `backend/app/services/matching/` | ✅ |
| 2.2b | Manual ASIN decide API + DB | review route, `review_decisions.manual_asin` | ✅ |
| 2.2c | Gemini multimodal (optional) | `matching/gemini.py` | ✅ |
| 2.3 | Google Sheets | `backend/app/services/spreadsheet/` | ✅ |
| 2.4 | ARQ workers + retry/DLQ | `backend/app/workers/` | ✅ |
| 2.5 | Alembic migrations | `backend/alembic/` | ✅ |
| 2.6 | CLI entrypoint | `python -m app.cli` | ✅ |

Phase 2 done (except 2.2c): scrape → match → DB → worker retry/DLQ → CLI path verified.

### Phase 2 local verification (M2)

See also: [production-local-setup.md](./production-local-setup.md).

```bash
bash scripts/smoke-m2.sh

docker compose up -d postgres redis
cd backend && source .venv/bin/activate
pip install -r requirements.txt
playwright install chromium
python -m app.cli migrate
python -m app.cli scrape --url "https://shopee.sg/..." --limit 5
python -m app.cli run --url "https://shopee.sg/..." --limit 5
arq app.workers.settings.WorkerSettings
```

## Phase 3: UI / API (shared)

| ID | Task | Deliverable | Status |
|----|------|-------------|--------|
| 3.1 | Dashboard UI | `frontend/src/app/page.tsx` | ✅ |
| 3.2 | Review UI | `frontend/src/app/review/[jobId]/` | ✅ |
| 3.3 | API client + types | `frontend/src/lib/api.ts` | ✅ |
| 3.4 | Job progress polling/SSE | hooks + API | ✅ MVP polling |
| 3.5 | FastAPI ↔ Redis | docker-compose verification | ✅ v1 |
| 3.6 | Manual ASIN UI | review screen §design 3.3 | ✅ v1 |

## Phase 4: Portfolio (public demo)

| ID | Task | Deliverable | Estimate |
|----|------|-------------|----------|
| 4.1 | Mock API polish | `MockResearchService` | ✅ |
| 4.2 | README and screenshots | `docs/images/dashboard.png`, `docs/images/review.png` | ✅ |
| 4.3 | Demo video (Loom, etc.) | `docs/videos/portfolio-demo.webm` | ✅ |
| 4.4 | Vercel deploy + CORS / rate limit | `backend/app/core/rate_limit.py`, public URL | ✅ |

## Milestones

```
M1: Mock research from frontend (portfolio)              ← done
M2: CLI scrape + amazon_search for one seller            ← scripts/smoke-m2.sh
M3: Review → Sheets E2E
M4: Public GitHub + demo URL
```

## Local start (portfolio)

No Postgres / Redis. `.env` from `bootstrap-local.sh`.

```bash
bash scripts/bootstrap-local.sh
# Terminal 1: backend uvicorn :8000
# Terminal 2: frontend npm run dev :3000
```

---

# WBS・開発ロードマップ

想定総工数: **30〜40 時間**（AI 駆動開発前提）

> **状態列は自動更新**: 成果物パスがリポジトリに存在すると `scripts/sync-wbs-roadmap.py` が ✅ に更新（`pre-commit` / `ci-check.sh` で実行）。README の Phase チェックボックスも連動。

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

## Phase 2: コアロジック（裏版） — ✅ 完了

| ID | タスク | 成果物 | 状態 |
|----|--------|--------|------|
| 2.1 | Playwright Shopee クローラー | `backend/app/services/scraper/` | ✅ |
| 2.2 | 候補マッチング（Amazon PA-API タイトル検索） | `backend/app/services/matching/` | ✅ |
| 2.2b | 手動 ASIN decide API + DB | review route, `review_decisions.manual_asin` | ✅ |
| 2.2c | Gemini マルチモーダル（任意） | `matching/gemini.py` | ✅ |
| 2.3 | Google Sheets 連携 | `backend/app/services/spreadsheet/` | ✅ |
| 2.4 | ARQ ワーカー + リトライ/DLQ | `backend/app/workers/` | ✅ |
| 2.5 | Alembic マイグレーション | `backend/alembic/` | ✅ |
| 2.6 | CLI エントリポイント | `python -m app.cli` | ✅ |

Phase 2 完了条件（2.2c 除く）: スクレイプ → マッチング → DB 永続化 → ワーカーリトライ/DLQ → CLI 検証パスが揃っていること。

### Phase 2 ローカル検証（M2）

See also: [production-local-setup.md](./production-local-setup.md) (裏版ローカル起動).

```bash
# 一括スモーク（推奨）
bash scripts/smoke-m2.sh

# 手動ステップ
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

## Phase 3: UI / API（共通）

| ID | タスク | 成果物 | 状態 |
|----|--------|--------|------|
| 3.1 | ダッシュボード UI | `frontend/src/app/page.tsx` | ✅ 先行完了 |
| 3.2 | レビュー UI | `frontend/src/app/review/[jobId]/` | ✅ 先行完了 |
| 3.3 | API クライアント + 型 | `frontend/src/lib/api.ts` | ✅ 先行完了 |
| 3.4 | ジョブ進捗ポーリング/SSE | hooks + API | ✅ MVP ポーリング |
| 3.5 | FastAPI ↔ Redis 本接続 | docker-compose 起動検証 | ✅ 初版 |
| 3.6 | 手動 ASIN 入力 UI | レビュー画面 §design 3.3 | ✅ 初版 |

## Phase 4: ポートフォリオ化（表版）

| ID | タスク | 成果物 | 工数目安 |
|----|--------|--------|----------|
| 4.1 | Mock API 完成度向上 | `MockResearchService` | ✅ |
| 4.2 | README・スクリーンショット | `docs/images/dashboard.png`, `docs/images/review.png` | ✅ |
| 4.3 | デモ動画（Loom 等） | `docs/videos/portfolio-demo.webm` | ✅ |
| 4.4 | Vercel デプロイ + CORS / レート制限 | `backend/app/core/rate_limit.py`, 公開 URL | ✅ |

## マイルストーン

```
M1: フロントから Mock リサーチ完了（portfolio）              ← 到達済み
    起動: bash scripts/bootstrap-local.sh → uvicorn + npm run dev
M2: CLI で 1 セラー実スクレイプ + amazon_search   ← scripts/smoke-m2.sh
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
