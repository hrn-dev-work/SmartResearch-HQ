# SmartResearch-HQ — 要件定義書

> 詳細設計・UI方針・MVP意思決定の本文は [design.md](./design.md) を参照。本書は要件の単一ソース（What）とする。  
> プロジェクト概要は [プロジェクト計画書.md](./プロジェクト計画書.md)。

## 1. 目的・スコープ

越境EC（Shopee）の SOLD 商品を抽出し、**プラガブルな候補マッチング**（既定: タイトルベース Amazon 検索）のうえ、人間がレビューしてスプレッドシートへ出力する。

> **プラガブルな候補マッチング**  
> 「候補を選定・マッチングするロジック（仕組み）をシステム本体から切り離し、後から自由に追加、差し替え、拡張できるように設計すること」

| 版 | 目的 | 本リポジトリでの扱い |
|----|------|----------------------|
| 表（portfolio） | 転職・提案デモ | Mock API + フロント + 設計 docs |
| 裏（production） | 実運用 | Playwright / 候補マッチング / Sheets 実装（非公開可） |

## 2. 機能要件

### 2.1 リサーチ開始

- ユーザーは Shopee ショップ URL（必須）と表示名（任意）を入力し、リサーチジョブを作成できる。
- API: `POST /api/v1/research`（[api-specification.md](./api-specification.md)）

### 2.2 ジョブ進捗・状態

- ジョブは `PENDING → SCRAPING → AI_INFERENCE → AWAITING_REVIEW → APPROVED/REJECTED → EXPORTED` のステートマシンに従う（[architecture.md](./architecture.md) §3）。
- `AI_INFERENCE` は **候補マッチング処理中** を表す（Gemini 専用ではない）。
- フロントは `GET /research/{job_id}` でステータス・進捗を表示する（MVP はポーリング、将来 SSE）。

### 2.3 レビュー（Human-in-the-loop）

- 各 Shopee 商品に対し、システムが提示した Amazon 候補（最大3件想定）から1件を選択、または却下できる。
- `MATCHING_PROVIDER=none` 時、または候補が空の場合は **ASIN を手入力** して確定できる（[api-specification.md](./api-specification.md) §decide）。
- API: `GET /research/{job_id}/items`, `POST /review/{item_id}/decide`

### 2.4 エクスポート

- 確定済みアイテムをジョブ単位でスプレッドシートへ出力できる。
- portfolio モードでは外部 API を呼ばず件数のみ返す。

### 2.5 データ永続化

- ジョブ・商品・候補・レビュー結果は PostgreSQL に保存する（[database-schema.md](./database-schema.md)）。
- portfolio モードはインメモリ Mock（Phase 2 で production が DB 接続）。

### 2.6 候補マッチング（production）

- 実装は `MATCHING_PROVIDER` で切り替える（[architecture.md](./architecture.md) §4）。
- **既定**: `amazon_search` — Shopee タイトルを正規化し Amazon PA-API キーワード検索で候補を返す。
- **代替**: `none` — 候補自動生成なし（手動レビューのみ）。
- **任意**: `gemini` — 画像+テキストのマルチモーダル推論（API クォータ制約のため後置き）。

## 3. 非機能要件

### 3.1 性能・応答時間

| 項目 | 要件 |
|------|------|
| API（同期） | ヘルス・一覧系は 500ms 以内（p95、ローカル想定） |
| スクレイピング | セラーあたり数分以内を目標（商品数に依存） |
| **候補マッチング** | **実測後に確定するが、UX を考慮し暫定で3秒以内を目標とする**（1商品あたり、`amazon_search` 1リクエスト想定） |
| フロント | レビュー一覧の初回表示 2秒以内（Mock / 同一リージョン想定） |

### 3.2 堅牢性

- CAPTCHA / IP ブロック時はワーカー単位で失敗し、API 全体は落とさない。
- 候補マッチング失敗時は `AI_FAILED` と監査ログ。Structured JSON（Gemini 利用時）または API レスポンスのパース失敗も同様。
- スクレイピングは対象サイトの ToS を尊重し、過剰なリクエストを避ける。

### 3.3 セキュリティ

- API キー・サービスアカウントは環境変数のみ。表版リポジトリに本番キーを含めない。

### 3.4 運用・可観測性

- ジョブステータスは DB と API で一貫して参照可能。
- 失敗ジョブはリトライ上限後 DLQ（裏版 Phase 2）。
- `GET /health` で `mode` と `matching_provider` を返し、実行構成を確認できる。

## 4. MVP スコープ（7つの意思決定）

以下は MVP で「やる / やらない」の境界。詳細な根拠・UIへの影響は [design.md §11](./design.md#11-mvpスコープ7つの意思決定) に記載し、本節では要件として要約のみ記す。

| # | 決定 | MVP での要件 |
|---|------|----------------|
| 1 | **表版（portfolio）を先行** | `APP_MODE=portfolio` を既定とし、Mock で E2E デモ可能であること |
| 2 | **認証なし** | 単一テナント・デモ利用者想定。ログイン画面・RBAC は MVP 外 |
| 3 | **入力はショップ URL のみ** | 一括 CSV・複数セラー同時投入は MVP 外 |
| 4 | **レビュー必須** | 候補の自動確定は行わず、全件 Human-in-the-loop |
| 5 | **マッチングはプラガブル** | 既定 `amazon_search`。Gemini は任意。固定スキーマで候補を返す |
| 6 | **進捗はポーリング** | SSE / WebSocket は MVP 外（Phase 3） |
| 7 | **Sheets 出力は portfolio ではログ相当** | 件数レスポンスのみ。実 Sheets API は production のみ |

## 5. 画面要件（概要）

| 画面 | パス | 要件 |
|------|------|------|
| リサーチ開始 | `/` | URL 入力・送信・エラー表示 |
| レビュー | `/review/[jobId]` | 商品一覧・候補選択・却下・手動 ASIN（`none` 時）・エクスポート |

UI のビジュアル要件（脱AI感・タイポグラフィ・余白）は [design.md §2](./design.md#2-uiデザイン原則) を参照。

## 6. 参照ドキュメント

- [プロジェクト計画書.md](./プロジェクト計画書.md)
- [architecture.md](./architecture.md)
- [api-specification.md](./api-specification.md)
- [database-schema.md](./database-schema.md)
- [wbs-roadmap.md](./wbs-roadmap.md)
- [design.md](./design.md)

## 7. WBS との対応

| WBS | 本書での扱い |
|-----|----------------|
| 要件定義書 | 本ドキュメント |
| §3.1 候補マッチング応答目標 | §3.1 |
| §4 MVP と design §11 | §4 + design §11 |
| マッチング方針（Gemini 非依存） | §2.6 + architecture §4 |
| 手動 ASIN | §2.3 + api-spec decide |
