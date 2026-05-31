# Database schema design

PostgreSQL 15+. ORM: SQLAlchemy 2.x (async).

## ER overview

```
sellers ──< research_jobs ──< job_items ──< amazon_candidates
                │                │
                │                └──< review_decisions
                └── (status state machine)
```

## Tables

### `sellers`

| Column | Type | Description |
|--------|------|-------------|
| id | UUID PK | |
| shopee_shop_url | TEXT UNIQUE NOT NULL | Target seller URL |
| display_name | VARCHAR(255) | Display name |
| created_at | TIMESTAMPTZ | |

### `research_jobs`

One job per “start research” action.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID PK | |
| seller_id | UUID FK → sellers | |
| status | VARCHAR(32) | State machine (below) |
| progress_pct | SMALLINT | 0–100 |
| error_code | VARCHAR(64) NULL | e.g. SCRAPE_BLOCKED |
| error_message | TEXT NULL | |
| retry_count | INT DEFAULT 0 | |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |
| completed_at | TIMESTAMPTZ NULL | |

**status values**: `PENDING`, `SCRAPING`, `SCRAPE_FAILED`, `AI_INFERENCE`, `AI_FAILED`, `AWAITING_REVIEW`, `APPROVED`, `REJECTED`, `EXPORTED`

> `AI_INFERENCE` = candidate matching in progress (legacy name).

### `job_items`

One Shopee SOLD line item.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID PK | |
| job_id | UUID FK → research_jobs | |
| shopee_item_id | VARCHAR(64) | |
| title | TEXT | |
| image_url | TEXT | |
| sold_count | INT NULL | |
| price_display | VARCHAR(64) NULL | |
| scrape_metadata | JSONB | Raw payload |
| created_at | TIMESTAMPTZ | |

### `amazon_candidates`

Matching output (`amazon_search` / `gemini`, etc.), max N per item.  
No rows when `MATCHING_PROVIDER=none`.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID PK | |
| job_item_id | UUID FK → job_items | |
| rank | SMALLINT | 1..n by confidence |
| asin | VARCHAR(16) | |
| amazon_url | TEXT | |
| title | TEXT | |
| confidence | NUMERIC(4,3) | 0–1 |
| reasoning | TEXT NULL | Audit trail |
| source | VARCHAR(32) NULL | `amazon_search` / `gemini`, etc. |
| created_at | TIMESTAMPTZ | |

### `review_decisions`

Human-in-the-loop outcome.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID PK | |
| job_item_id | UUID FK UNIQUE | One decision per item |
| chosen_candidate_id | UUID FK → amazon_candidates NULL | When picking a candidate |
| manual_asin | VARCHAR(16) NULL | Manual entry (`none`, etc.) |
| rejected | BOOLEAN DEFAULT FALSE | True when rejected |
| decided_at | TIMESTAMPTZ | |
| exported_at | TIMESTAMPTZ NULL | After Sheets export |

**Constraint**: `chosen_candidate_id` and `manual_asin` are mutually exclusive (or reject).

## Indexes

```sql
CREATE INDEX idx_research_jobs_status ON research_jobs(status);
CREATE INDEX idx_research_jobs_seller ON research_jobs(seller_id);
CREATE INDEX idx_job_items_job ON job_items(job_id);
CREATE INDEX idx_amazon_candidates_item ON amazon_candidates(job_item_id);
```

## Migrations

Alembic under `backend/alembic/` (initial migration in Phase 2).

Portfolio Mock uses in-memory storage. Apply this schema when connecting production DB.

---

# データベーススキーマ設計

PostgreSQL 15+ を想定。ORM は SQLAlchemy 2.x（async）。

## ER 概要

```
sellers ──< research_jobs ──< job_items ──< amazon_candidates
                │                │
                │                └──< review_decisions
                └── (status ステートマシン)
```

## テーブル定義

### `sellers`

| カラム | 型 | 説明 |
|--------|-----|------|
| id | UUID PK | |
| shopee_shop_url | TEXT UNIQUE NOT NULL | 対象セラー URL |
| display_name | VARCHAR(255) | 表示名 |
| created_at | TIMESTAMPTZ | |

### `research_jobs`

1 回の「リサーチ開始」に対応するジョブ単位。

| カラム | 型 | 説明 |
|--------|-----|------|
| id | UUID PK | |
| seller_id | UUID FK → sellers | |
| status | VARCHAR(32) | ステートマシン（下記） |
| progress_pct | SMALLINT | 0–100 |
| error_code | VARCHAR(64) NULL | SCRAPE_BLOCKED 等 |
| error_message | TEXT NULL | |
| retry_count | INT DEFAULT 0 | |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |
| completed_at | TIMESTAMPTZ NULL | |

**status 値**: `PENDING`, `SCRAPING`, `SCRAPE_FAILED`, `AI_INFERENCE`, `AI_FAILED`, `AWAITING_REVIEW`, `APPROVED`, `REJECTED`, `EXPORTED`

> `AI_INFERENCE` = 候補マッチング処理中（名称は後方互換）。

### `job_items`

Shopee から抽出した SOLD 商品 1 件。

| カラム | 型 | 説明 |
|--------|-----|------|
| id | UUID PK | |
| job_id | UUID FK → research_jobs | |
| shopee_item_id | VARCHAR(64) | |
| title | TEXT | |
| image_url | TEXT | |
| sold_count | INT NULL | |
| price_display | VARCHAR(64) NULL | |
| scrape_metadata | JSONB | 生データ退避 |
| created_at | TIMESTAMPTZ | |

### `amazon_candidates`

候補マッチング（`amazon_search` / `gemini` 等）が返した Amazon 候補（最大 N 件 / item）。  
`MATCHING_PROVIDER=none` 時は行なし。

| カラム | 型 | 説明 |
|--------|-----|------|
| id | UUID PK | |
| job_item_id | UUID FK → job_items | |
| rank | SMALLINT | 信頼度順 1..n |
| asin | VARCHAR(16) | |
| amazon_url | TEXT | |
| title | TEXT | |
| confidence | NUMERIC(4,3) | 0–1 |
| reasoning | TEXT NULL | マッチング根拠（監査用） |
| source | VARCHAR(32) NULL | `amazon_search` / `gemini` 等 |
| created_at | TIMESTAMPTZ | |

### `review_decisions`

Human-in-the-loop の確定結果。

| カラム | 型 | 説明 |
|--------|-----|------|
| id | UUID PK | |
| job_item_id | UUID FK UNIQUE | 1 item 1 decision |
| chosen_candidate_id | UUID FK → amazon_candidates NULL | 候補選択時 |
| manual_asin | VARCHAR(16) NULL | 手動入力時（`none` モード等） |
| rejected | BOOLEAN DEFAULT FALSE | 却下時 true |
| decided_at | TIMESTAMPTZ | |
| exported_at | TIMESTAMPTZ NULL | Sheets 反映後 |

**制約**: `chosen_candidate_id` と `manual_asin` は排他（どちらか一方、または却下）。

## インデックス

```sql
CREATE INDEX idx_research_jobs_status ON research_jobs(status);
CREATE INDEX idx_research_jobs_seller ON research_jobs(seller_id);
CREATE INDEX idx_job_items_job ON job_items(job_id);
CREATE INDEX idx_amazon_candidates_item ON amazon_candidates(job_item_id);
```

## マイグレーション

Alembic を `backend/alembic/` に配置（Phase 2 で初期マイグレーション生成）。

portfolio モード（Mock）は DB を使用せずインメモリ。production 接続時に本スキーマを適用する。
