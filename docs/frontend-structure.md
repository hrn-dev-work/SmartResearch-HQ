# フロントエンド構造（Next.js App Router）

コードベースの画面・コンポーネント・依存関係の地図（Mermaid）。

- **概要・利点・使い方**: [frontend-structure-guide.md](./frontend-structure-guide.md)
- **日常のレイヤー確認**: [React DevTools](https://react.dev/learn/react-developer-tools)（Components タブ）

> **更新タイミング**: ルート追加、`components/` 新規、主要な lib 分割時に §2〜§4 を見直す。

---

## 1. 画面遷移

```mermaid
flowchart LR
  MW["middleware.ts\n初回 locale cookie"]
  L["layout.tsx\nRootLayout"]
  D["/\nDashboardPage"]
  R["/review/[jobId]\nReviewPage"]
  API["lib/api.ts\nFastAPI"]

  MW --> L
  L --> D
  L --> R
  D -->|"createResearch → job_id"| R
  R -->|"Link 戻る"| D
  D --> API
  R --> API
```

| ルート | ファイル | 役割 |
|--------|----------|------|
| `/` | `app/page.tsx` | Shopee URL 入力 → リサーチ開始 |
| `/review/[jobId]` | `app/review/[jobId]/page.tsx` | ジョブ進捗・ASIN 候補レビュー・エクスポート |

---

## 2. コンポーネントツリー（Figma Layers 相当）

### 2.1 共通ラッパー

```mermaid
flowchart TB
  RL["RootLayout\napp/layout.tsx"]
  LP["LocaleProvider"]
  CH["{children} ページ"]

  RL --> LP --> CH
```

### 2.2 `/` ダッシュボード

```mermaid
flowchart TB
  DP["DashboardPage\napp/page.tsx"]
  H["Header"]
  LT["LocaleToggle"]
  ADT["AboutDemoTrigger"]
  ADD["AboutDemoDialog"]
  M["main"]
  S1["section · 見出し"]
  S2["section · フォーム"]
  AS["aside · Metric × 3"]

  DP --> H
  H --> LT
  H --> ADT
  ADT --> ADD
  DP --> M
  M --> S1
  M --> S2
  M --> AS
```

`Metric` は `page.tsx` 内のローカルコンポーネント（未共有化）。

### 2.3 `/review/[jobId]` レビュー

```mermaid
flowchart TB
  RP["ReviewPage\n（key=jobId）"]
  RPB["ReviewPageBody"]
  H["Header"]
  M["main"]
  MH["header · 戻る / タイトル / StatusBadge / エクスポート"]
  SEC["section · 商品一覧"]
  RIR["ReviewItemRow × N\n（page 内ローカル）"]

  RP --> RPB
  RPB --> H
  RPB --> M
  M --> MH
  M --> SEC
  SEC --> RIR
```

---

## 3. モジュール依存（import 関係）

```mermaid
flowchart TB
  subgraph pages["pages (app/)"]
    P["page.tsx"]
    RV["review/.../page.tsx"]
    LY["layout.tsx"]
  end

  subgraph components["components/"]
    HDR["Header"]
    SB["StatusBadge"]
    LCP["LocaleProvider"]
    LCT["LocaleToggle"]
    ADT["AboutDemoTrigger"]
    ADD["AboutDemoDialog"]
  end

  subgraph hooks["hooks/"]
    UJP["useJobProgress"]
  end

  subgraph lib["lib/"]
    API["api.ts"]
    ASIN["asin.ts"]
    LOC["locale.ts"]
    MSG["messages/*"]
    FMT["format-message.ts"]
    UIC["ui-classes.ts"]
    TYP["types.ts"]
  end

  MW["middleware.ts"] --> LOC

  LY --> LCP
  LY --> MSG
  LY --> LOC

  P --> HDR
  P --> LCP
  P --> API
  P --> UIC

  RV --> HDR
  RV --> SB
  RV --> LCP
  RV --> UJP
  RV --> API
  RV --> ASIN
  RV --> FMT
  RV --> MSG
  RV --> UIC
  RV --> TYP

  HDR --> ADT
  HDR --> LCT
  HDR --> UIC
  ADT --> ADD
  ADT --> LCP
  LCT --> LCP
  LCT --> LOC
  SB --> LCP
  SB --> TYP
  ADD --> LCP

  UJP --> API
  UJP --> TYP

  API --> TYP
  ASIN --> MSG
```

---

## 4. 多言語（i18n）

```mermaid
sequenceDiagram
  participant Browser
  participant MW as middleware.ts
  participant Layout as layout.tsx
  participant LP as LocaleProvider
  participant UI as 各コンポーネント

  Browser->>MW: 初回リクエスト（cookie なし）
  MW->>MW: geo / Accept-Language → locale
  MW->>Browser: Set-Cookie locale
  Browser->>Layout: リクエスト（cookie 付き）
  Layout->>Layout: getMessages(locale)
  Layout->>LP: locale + messages
  LP->>UI: useLocale()
  UI->>UI: messages.dashboard / review 等
```

- 辞書: `lib/messages/ja.ts`, `en.ts`
- Cookie 書き込み: `lib/locale.ts`（`LocaleToggle` 経由）および `middleware.ts`（初回のみ）
- 詳細: [design.md §2.6](./design.md)

---

## 5. ディレクトリ早見表

```
frontend/src/
├── app/
│   ├── layout.tsx              # RootLayout + LocaleProvider
│   ├── page.tsx                # / ダッシュボード
│   └── review/[jobId]/page.tsx # レビュー
├── components/
│   ├── Header.tsx
│   ├── StatusBadge.tsx
│   ├── LocaleProvider.tsx
│   ├── LocaleToggle.tsx
│   ├── AboutDemoTrigger.tsx
│   └── AboutDemoDialog.tsx
├── hooks/
│   └── useJobProgress.ts       # ジョブポーリング
├── lib/
│   ├── api.ts                  # REST クライアント
│   ├── asin.ts                 # ASIN バリデーション
│   ├── locale.ts
│   ├── format-message.ts
│   ├── ui-classes.ts           # 共通 Tailwind クラス
│   ├── types.ts
│   └── messages/               # ja / en 辞書
└── middleware.ts               # 初回 locale 判定
```

---

## 6. ローカルでの確認手順

1. `bash scripts/bootstrap-local.sh` で API + UI 起動
2. Chrome [React Developer Tools](https://react.dev/learn/react-developer-tools) → **Components** タブ
3. `/` と `/review/{任意の jobId}` でツリーを比較

構造変更後は本ファイルの Mermaid を先に更新し、実 DOM と DevTools 表示が一致するか確認する。
