# API 仕様（v1）

Base URL: `/api/v1`  
Content-Type: `application/json`

## 共通

### エラーレスポンス

```json
{
  "error": {
    "code": "SCRAPE_BLOCKED",
    "message": "Human readable message",
    "details": {}
  }
}
```

| HTTP | 用途 |
|------|------|
| 400 | バリデーション |
| 404 | リソースなし |
| 409 | 状態遷移不可 |
| 503 | 外部依存一時不可 |

### エラーコード（主要）

| code | 意味 |
|------|------|
| `SCRAPE_BLOCKED` | CAPTCHA / IP ブロック |
| `AI_FAILED` | 候補マッチング失敗 |
| `INVALID_ASIN` | 手動 ASIN 形式不正 |
| `INVALID_STATE` | ジョブ状態遷移不可 |

---

## `GET /health`

```json
{
  "status": "ok",
  "mode": "portfolio",
  "matching_provider": "amazon_search"
}
```

| フィールド | 値 |
|-----------|-----|
| `mode` | `portfolio` \| `production` |
| `matching_provider` | `amazon_search` \| `none` \| `gemini` |
| `redis` | production 時のみ: `ok` \| `unavailable`。portfolio では省略 |

production 検証: `docker compose up -d redis` 後、`mode=production` で `redis: ok` になること。

---

## `POST /research`

リサーチジョブを新規作成し、キューに投入する。

**Request**

```json
{
  "shopee_shop_url": "https://shopee.sg/shop/123456",
  "seller_display_name": "Optional Shop Name"
}
```

**Response 201**

```json
{
  "job_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "PENDING",
  "progress_pct": 0
}
```

portfolio 時は即 `AWAITING_REVIEW` / `progress_pct: 100` を返す場合あり（Mock）。

---

## `GET /research/{job_id}`

ジョブ概要と進捗。

**Response 200**

```json
{
  "job_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "AI_INFERENCE",
  "progress_pct": 45,
  "seller": {
    "shopee_shop_url": "https://shopee.sg/shop/123456",
    "display_name": "Demo Shop"
  },
  "item_count": 12,
  "error": null,
  "created_at": "2026-05-17T12:00:00Z",
  "updated_at": "2026-05-17T12:01:30Z"
}
```

`status` の `AI_INFERENCE` は候補マッチング処理中を表す。

---

## `GET /research/{job_id}/items`

レビュー画面用。ページネーション対応。

**Query**: `?page=1&page_size=20`

**Response 200**

```json
{
  "items": [
    {
      "item_id": "item-uuid",
      "title": "Wireless Earbuds Pro",
      "image_url": "https://cf.shopee.sg/file/...",
      "sold_count": 1523,
      "candidates": [
        {
          "candidate_id": "cand-uuid",
          "rank": 1,
          "asin": "B0XXXXXX",
          "amazon_url": "https://www.amazon.com/dp/B0XXXXXX",
          "title": "Similar product on Amazon",
          "confidence": 0.87
        }
      ],
      "decision": null
    }
  ],
  "page": 1,
  "page_size": 20,
  "total": 12
}
```

---

## `POST /review/{item_id}/decide`

ユーザーが正解候補を選択、手動 ASIN で確定、または却下する。

### パターン A: 候補から選択

**Request**

```json
{
  "candidate_id": "cand-uuid"
}
```

### パターン B: 手動 ASIN（`MATCHING_PROVIDER=none` または候補空）

**Request**

```json
{
  "candidate_id": null,
  "manual_asin": "B0XXXXXX"
}
```

- `manual_asin`: 10 文字（先頭 `B` + 英数字 9 文字）。サーバー側で `amazon_url` を生成。
- `candidate_id` と `manual_asin` は同時指定不可。

### パターン C: 却下

**Request**

```json
{
  "candidate_id": null,
  "rejected": true
}
```

**Response 200**

```json
{
  "item_id": "item-uuid",
  "status": "APPROVED",
  "exported": false
}
```

却下時は `"status": "REJECTED"`。

> **Note**: 手動 ASIN（パターン B）は Phase 2 で API・DB 実装。portfolio Mock では Phase 2 まで未対応可。

---

## `POST /research/{job_id}/export`

確定済みアイテムをスプレッドシートへ一括出力（production のみ実処理）。

**Response 202**

```json
{
  "job_id": "550e8400-e29b-41d4-a716-446655440000",
  "exported_count": 10,
  "skipped_count": 2
}
```

---

## Portfolio Mock 挙動

`APP_MODE=portfolio` 時:

- `POST /research` は即座にフィクスチャデータで `AWAITING_REVIEW` まで進行。
- 固定の Shopee 画像 URL と Amazon 候補 3 件を返す。
- `export` は `exported_count` を返すが外部 API は呼ばない。
- `POST /review/{item_id}/decide` で `manual_asin` を受け付ける（Mock 内で確定保存）。
- Postgres / Redis / 外部マッチング API は使用しない。
