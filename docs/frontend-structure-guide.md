# フロント構造可視化ガイド

Next.js フロントの画面・コンポーネント・依存関係を、コードと並行して把握するためのガイド。

| ドキュメント | 内容 |
|--------------|------|
| **本ファイル** | 概要・利点・使い方 |
| [frontend-structure.md](./frontend-structure.md) | Mermaid 図（ルート / レイヤー / import / i18n） |

---

## 概要

SmartResearch-HQ のフロントは **Next.js 16 App Router**（`frontend/src/`）。画面は現状 2 ルート（`/` ダッシュボード、`/review/[jobId]` レビュー）で、共有コンポーネント・hooks・lib がそれを支える。

**可視化は 2 層**で使い分ける。

| 層 | 手段 | 役割 |
|----|------|------|
| **ライブ** | React DevTools | 実行中アプリのコンポーネントツリー（Figma Layers 相当） |
| **ドキュメント** | Mermaid（[frontend-structure.md](./frontend-structure.md)） | ルート・import・i18n の地図。PR レビュー・オンボーディング用 |

Figma は UI **デザイン**向け。既存コードの構造把握には DevTools + Mermaid の方がコスト対効果が高い（Figma 無料 Starter でも自動連動はしない）。

---

## 利点

### 1. オンボーディングが速い

新規参加者が「どの画面がどのファイルか」「Header がどこで使われるか」を、図と DevTools で 15 分以内に把握できる。

### 2. PR レビューの抜け漏れが減る

ルート追加・コンポーネント分割時に [frontend-structure.md](./frontend-structure.md) を更新すれば、**import の影響範囲**（例: `LocaleProvider` 配下の文案）をレビュアーが確認しやすい。

### 3. Figma 不要でレイヤー確認できる

React DevTools の Components タブは **実際の React ツリー**を表示する。デザインファイルとコードの二重管理が不要。

### 4. 追加ツール・コストがほぼゼロ

- DevTools: ブラウザ拡張（無料）
- Mermaid: Markdown 内蔵（GitHub / VS Code プレビュー）
- Storybook / dependency-cruiser: 規模が大きくなってから検討で十分

### 5. アーキテクチャ正本との役割分担が明確

- システム全体 → [architecture.md](./architecture.md)
- フロント詳細 → [frontend-structure.md](./frontend-structure.md)（本ガイドからリンク）

---

## 使い方

### A. 日常 — React DevTools（レイヤー確認）

1. Chrome に [React Developer Tools](https://react.dev/learn/react-developer-tools) をインストール
2. ローカル起動:

   ```bash
   bash scripts/bootstrap-local.sh
   ```

3. `http://localhost:3000` を開く
4. DevTools → **Components** タブ → 左上の選択ツールで要素をクリック

**確認ポイント**

| 画面 | 見るツリー |
|------|------------|
| `/` | `DashboardPage` → `Header` → `main` → `Metric` |
| `/review/{jobId}` | `ReviewPageBody` → `StatusBadge` → `ReviewItemRow` |

リサーチ開始後に `/review/...` へ遷移すると、ジョブ ID 付きのレビュー画面も確認できる。

### B. 設計共有 — Mermaid 図

1. [frontend-structure.md](./frontend-structure.md) を開く
2. **§1** 画面遷移、**§2** コンポーネントツリー、**§3** import 関係を参照
3. **§4** で i18n（middleware → LocaleProvider）の流れを確認

**プレビュー方法**

| 環境 | 操作 |
|------|------|
| GitHub | リポジトリ上で md を開く（Mermaid 自動レンダリング） |
| VS Code | Markdown プレビュー（必要なら Mermaid 拡張） |
| Cursor | エディタで md プレビュー |

### C. 構造を変えたとき — ドキュメント更新

次のいずれかを行ったら [frontend-structure.md](./frontend-structure.md) の **§2〜§4** を更新する。

- `app/` にルート（ページ）を追加
- `components/` に共有コンポーネントを追加
- `lib/` / `hooks/` の主要な依存関係を変更

更新後、DevTools で実ツリーと図が一致するか 1 画面ずつ確認する。

### D. いつ Figma を足すか

次のニーズが出たら [Figma Starter（無料）](https://www.figma.com/pricing/) を検討する。

- 新画面のワイヤー・モックを先にデザインしたい
- 非エンジニアと画面レビューしたい
- localhost の見た目を Figma に取り込みたい（[html.to.design](https://html.to.design/) 等）

**構造把握だけ**なら DevTools + Mermaid で足りる。

---

## クイックリンク

- 詳細図: [frontend-structure.md](./frontend-structure.md)
- システム全体: [architecture.md](./architecture.md)
- UI / i18n 仕様: [design.md §2.6](./design.md)
- フロント実装メモ: [frontend/AGENTS.md](../frontend/AGENTS.md)（ローカル・gitignore の場合あり）
