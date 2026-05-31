# SmartResearch-HQ — 設計書

要件の What は [requirements.md](./requirements.md)。本書は How（アーキテクチャ補足・UI・MVP意思決定の詳細）を扱う。  
概要は [プロジェクト計画書.md](./プロジェクト計画書.md)。

## 1. システム構成

[architecture.md](./architecture.md) を正とする。二刀流（`APP_MODE`）による Mock / 本番切り替えは変更しない。

## 2. UIデザイン原則

### 2.1 脱AI感

- 安易なカードレイアウト（`border` + `shadow-md` の多用）を避ける。
- 情報階層は **8px 単位の余白** と **タイポグラフィのジャンプ率**（例: 14 → 16 → 24 → 32px）で表現する。
- 装飾より内容。一覧・フォームはフラットな白面 + 区切り線（`border-slate-200`）で十分。

### 2.2 カラー

| 用途 | クラス例 |
|------|----------|
| ページ背景 | `bg-slate-50` |
| コンテンツ面 | `bg-white` |
| 見出し | `text-slate-900` |
| 補助文 | `text-slate-500` |
| アクセント | `text-slate-900` / ボタン `bg-slate-900`（過度なビビッドカラー禁止） |

### 2.3 インタラクション

- クリッカブル要素は `transition-colors duration-200`（必要なら `active:scale-[0.98]`）。
- フォーカス: `focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400 focus-visible:ring-offset-2`。

### 2.4 密度

- セクション間は `space-y-12` 以上を基本。Vercel / Linear 系のクリーンな SaaS を目標。

### 2.5 コピー（脱AI文）

- 禁止: 「シームレスに」「革新的な」「包括的なソリューション」「ワンストップ」。
- 推奨: 動詞で始める短い文（例: 「Shopee の URL を貼ってリサーチを開始」）。
- 英語 UI の場合も同様。過剰な感嘆・絵文字は使わない。

### 2.6 UI 言語（必須・全プロジェクト共通方針）

開発者のグローバルルール `~/.cursor/rules/ui-i18n-locale.mdc` と同じ。

| 項目 | 方針 |
|------|------|
| 文言の置き場 | `frontend/src/lib/messages/ja.ts` / `en.ts`（べた書き禁止） |
| 初回既定 | 日本からのアクセス → `ja`、それ以外 → `en`（middleware で IP 国コード） |
| ユーザー操作 | ヘッダーに **JA \| EN** トグル。手動選択は cookie で保持し、地域既定より優先 |
| DB | **UI 言語は保存しない**（cookie のみ）。ログイン後の端末横断設定が必要になったら別途 |

## 3. 画面構成

### 3.1 リサーチ開始（`/`）

- ヒーロー: 1行タイトル + 1行説明のみ。
- フォーム: URL（必須）、表示名（任意）、プライマリボタン1つ。
- サイドに数値メトリクス（任意・テキストベース、カード装飾最小）。

### 3.2 レビュー（`/review/[jobId]`）

- ヘッダー: 戻るリンク、ジョブ名、ステータスバッジ、エクスポート。
- 商品行: 左ソース（画像+タイトル）、右候補リスト（ラジオ的選択 UI）。
- 決定済みは視覚的に muted（`opacity-60`）で区別。

### 3.3 手動 ASIN 入力（`MATCHING_PROVIDER=none` または候補空）

- 候補リストの下に ASIN 入力フィールド + 「この ASIN で確定」ボタン。
- 入力は 10 文字（B + 9 英数字）を想定。バリデーションエラーは行内テキストで表示。
- API: `POST /review/{item_id}/decide` に `manual_asin` を渡す（[api-specification.md](./api-specification.md)）。
- Phase 2 で UI 実装。portfolio Mock では候補選択 UI のみでも可。

## 4. コンポーネント方針

- 共通: `Header`, `StatusBadge`。
- ページ固有ロジックは page 内 co-location 可。過剰な抽象化は MVP では不要。

## 5. API 連携（フロント）

- `frontend/src/lib/api.ts` を単一の HTTP 層とする。
- 型は `frontend/src/lib/types.ts` と API 仕様を同期。

## 6. エラー・空状態

- エラー: 赤背景のバナーではなく、`text-red-600` + 左ボーダー `border-l-2 border-red-500 pl-3`。
- ローディング: スピナーより「読み込み中…」のテキスト + `animate-pulse` のスケルトン（任意）。
- 候補空: 「候補がありません。ASIN を入力してください」（`none` 時）。

## 7. 将来拡張（MVP 外）

- SSE 進捗、認証、ダークモード切替、一括インポート。

## 8. データモデル

[database-schema.md](./database-schema.md) を参照。

## 9. API

[api-specification.md](./api-specification.md) を参照。

## 10. デプロイ

- フロント: Vercel
- API: Railway / Fly.io 等（architecture §8）
- Phase 4: 本番 CORS origin 固定、公開 API のレート制限

## 11. MVPスコープ（7つの意思決定）

requirements.md §4 と対応。ここでは **根拠と設計への影響** のみ記載し、要件の重複記述は避ける。

### D1. 表版（portfolio）先行

- **根拠**: 公開リポジトリでデモ完走が最優先。スクレイピング・プロンプトは非公開可。
- **設計影響**: `MockResearchService` が即 `AWAITING_REVIEW` まで進める。UI に「Demo」バッジ表示可。Postgres / Redis 不要。

### D2. 認証なし

- **根拠**: ポートフォリオ閲覧者向け。実運用前に Auth0 等を検討。
- **設計影響**: API に Authorization ヘッダー不要。CORS は開発 origin のみ（本番は Phase 4）。

### D3. ショップ URL のみ

- **根拠**: 入力 UX を単純化。バルクは Phase 3 以降。
- **設計影響**: ダッシュボードは単一フォーム。ドラッグ&ドロップは MVP では必須としない（URL 貼り付け中心）。

### D4. レビュー必須

- **根拠**: ASIN 誤マッチはビジネスリスク。Human-in-the-loop が価値提案の核。
- **設計影響**: 候補ごとに明示的 Select / Reject。自動エクスポートなし。

### D5. マッチングはプラガブル（Gemini 非依存）

- **根拠**: Gemini API クォータ制約。Human-in-the-loop が価値の核であり、候補生成方式は差し替え可能にする。
- **設計影響**: `MATCHING_PROVIDER=amazon_search|none|gemini`。Amazon 検索は PA-API 5.0 を第一候補（architecture §4.2）。候補は `confidence` 数値付き固定スキーマ。`none` 時は §3.3 手動 ASIN UI。

### D6. 進捗ポーリング

- **根拠**: SSE 実装コストを Phase 3 に延期。
- **設計影響**: レビュー画面は mount 時 1 回 fetch。将来 `useJobProgress` hook 追加。

### D7. portfolio で Sheets はログ相当

- **根拠**: サービスアカウントを表版に載せない。
- **設計影響**: Export ボタンは残し、トーストで件数表示のみ。
