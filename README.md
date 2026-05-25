# SmartResearch-HQ

越境EC（Shopee 等）の商品リサーチと Shopee→Amazon 名寄せを、**スクレイピング・候補マッチング・Human-in-the-loop レビュー**で支援するシステムです。

---

## 概要

手作業で行われがちな「商品調査 → Amazon 候補の抽出 → 人による確定」を、ワークフローとして自動化します。  
同一コードベース上で、**デモ環境**と**本番環境**の 2 モードを切り替えて運用できます。

| モード | 用途 | 本リポジトリでの内容 |
|--------|------|----------------------|
| **Portfolio**（デモ環境） | 提案・検証・デモンストレーション | Mock API、フロントエンド、設計ドキュメント |
| **Production**（本番環境） | 実際の業務運用 | Playwright、マッチング、Google Sheets 連携（非公開実装を含む） |

デモ環境では外部 API や本番スクレイピングに依存せず、フィクスチャデータで一連の画面操作を確認できます。

---

## 主な機能

- Shopee 商品 URL からのリサーチジョブ投入
- Amazon 候補の提示とレビュー画面での確定（Human-in-the-loop）
- ジョブ進捗の可視化（ダッシュボード）
- 本番モード向け: Playwright による抽出、Amazon 検索連携、スプレッドシート出力（Phase 2 以降）

---

## 技術構成

| 層 | 技術 |
|----|------|
| フロントエンド | Next.js 16, TypeScript, Tailwind CSS |
| バックエンド | FastAPI, Pydantic v2 |
| インフラ | PostgreSQL 16, Redis 7（本番検証時は `docker compose`） |
| Phase 2 以降 | Playwright, Amazon PA-API タイトル検索, Google Sheets（Gemini は任意） |

---

## デモの起動（Portfolio / Mock）

Postgres と Redis は**不要**です。

```bash
cd ~/workspace/SmartResearch-HQ
bash scripts/bootstrap-local.sh
```

**API**

```bash
cd backend && source .venv/bin/activate
uvicorn app.main:app --reload --port 8000
```

`GET http://localhost:8000/api/v1/health` → `{ "status": "ok", "mode": "portfolio", ... }`

**UI**

```bash
cd frontend && npm run dev
```

http://localhost:3000 を開き、Shopee URL を入力 → レビュー画面で Amazon 候補を確認できます。

本番モードの動作確認（任意）:

```bash
cp .env.example .env
docker compose up -d postgres redis
```

---

## リポジトリ構成

```
├── docs/           # 設計・要件・アーキテクチャ
├── frontend/       # Next.js ダッシュボード & レビュー UI
├── backend/        # FastAPI（portfolio 時は Mock サービス）
├── docker-compose.yml
└── scripts/        # bootstrap、CI、自動化
```

---

## ドキュメント

| 資料 | 内容 |
|------|------|
| [プロジェクト計画書](docs/プロジェクト計画書.md) | 目的・戦略・マッチング方針 |
| [要件定義](docs/requirements.md) | 機能要件・受入条件 |
| [設計（UI・MVP）](docs/design.md) | 画面・UX の設計根拠 |
| [アーキテクチャ](docs/architecture.md) | システム構成・状態遷移 |
| [DB スキーマ](docs/database-schema.md) | データモデル |
| [API 仕様](docs/api-specification.md) | REST I/O |
| [WBS・ロードマップ](docs/wbs-roadmap.md) | フェーズ別タスクと進捗 |
| [Git ブランチ運用](docs/git-workflow.md) | ブランチ・PR・CI |

---

## ロードマップ

WBS 表（[docs/wbs-roadmap.md](docs/wbs-roadmap.md)）と連動し、`pre-commit` で README のチェックが自動更新されます。

- [x] **Phase 1** — 設計・モノレポ・ドキュメント整合
- [x] **Phase 2** — Playwright / Amazon 検索 / Sheets / ワーカー
- [x] **Phase 3** — 進捗ポーリング・Redis 本接続・手動 ASIN UI
- [ ] **Phase 4** — 公開デモ・Vercel デプロイ

---

## 開発者向け

### 前提環境

| 項目 | 備考 |
|------|------|
| OS | **WSL Ubuntu**（Windows 上）。Git Bash + UNC パスは venv 破損の原因になるため非推奨 |
| Python | **3.12** |
| Node.js | **20 LTS**（CI と同じ） |
| エディタ | Cursor または VS Code。WSL 側 `~/workspace/SmartResearch-HQ` で開く |
| Docker | 本番検証（Postgres / Redis）時のみ |

初回セットアップ:

```bash
bash scripts/bootstrap-local.sh
bash scripts/install-git-hooks.sh
```

push 前の品質チェック: `bash scripts/ci-check.sh`（Ruff + pytest + ESLint + build）

### 環境変数

| 変数 | 説明 |
|------|------|
| `APP_MODE` | `portfolio`（Mock） / `production` |
| `MATCHING_PROVIDER` | `amazon_search`（既定） / `none` / `gemini` |
| `AMAZON_PAAPI_*` | PA-API 5.0（production 時） |
| `GEMINI_API_KEY` | `gemini` 利用時のみ（コミット禁止） |
| `NEXT_PUBLIC_API_URL` | フロント → API（既定 `http://localhost:8000/api/v1`） |

`.env.example` をコピーするか、`bootstrap-local.sh` で生成。`.env` は git 管理外です。

### 自動化

| タイミング | 内容 |
|------------|------|
| `git commit` | WBS ロードマップ + README フェーズチェック |
| `git push` | PR 自動作成・CI チェックボックス同期 |
| GitHub CI | PR 本文の CI チェックを自動 `[x]` |

---

## ライセンス・公開範囲

本リポジトリは非公開運用を前提としています。  
デモ環境（portfolio）では、スクレイピングの詳細実装やプロプライエタリなプロンプト等を含めない構成とし、本番環境（production）向けの実装は別管理としています。

---

## English summary

**SmartResearch-HQ** automates cross-border e-commerce product research and Shopee→Amazon matching with scraping (production), candidate matching, and human review.

| Mode | Use case | In this repository |
|------|----------|-------------------|
| **Portfolio** | Demos, evaluation, stakeholder walkthroughs | Mock API, frontend, design docs |
| **Production** | Live operations | Playwright, matching, Google Sheets (private implementation) |

Quick demo: `bash scripts/bootstrap-local.sh`, then run backend (`uvicorn`) and frontend (`npm run dev`). No database required for portfolio mode.
