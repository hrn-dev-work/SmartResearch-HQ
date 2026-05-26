# SmartResearch-HQ

Cross-border e-commerce product research and Shopee→Amazon matching with scraping, candidate matching, and human review.

| Edition | Purpose | This repo |
|---------|---------|-----------|
| **Portfolio** | Demo for hiring / proposals | Mock API + frontend + design docs |
| **Production** | Real operations | Playwright, matching, Google Sheets (private) |

---

越境EC（Shopee 等）の商品リサーチ・名寄せを **スクレイピング + 候補マッチング + Human-in-the-loop** で自動化するシステム。

| 版 | 目的 | 本リポジトリ |
|----|------|-------------|
| **表**（ポートフォリオ） | 転職・提案用デモ | Mock API + フロント + 設計 docs |
| **裏**（完全版） | 実運用・副収入 | Private で Playwright / マッチング / Sheets |

## Tech stack

- **Frontend**: Next.js 16, TypeScript, Tailwind CSS
- **Backend**: FastAPI, Pydantic v2
- **Infra**: PostgreSQL 16, Redis 7 (`docker compose` for production verification)
- **Phase 2+**: Playwright, Amazon PA-API title search, Google Sheets (Gemini optional)

---

## 技術スタック

- **Frontend**: Next.js 16, TypeScript, Tailwind CSS
- **Backend**: FastAPI, Pydantic v2
- **Infra**: PostgreSQL 16, Redis 7（docker compose — production 検証用）
- **Phase 2+**: Playwright, Amazon PA-API タイトル検索, Google Sheets（Gemini は任意）

## Development setup

### Prerequisites

| Item | Version / notes |
|------|-----------------|
| OS | **WSL Ubuntu** on Windows. Avoid Git Bash + UNC paths (breaks venv) |
| Python | **3.12** (`python3.12-venv` if needed) |
| Node.js | **20 LTS** (same as CI) |
| Editor | **Cursor** or VS Code — open `~/workspace/SmartResearch-HQ` from WSL |
| Docker | Optional — for production verification (Postgres / Redis) |

### First-time bootstrap

```bash
cd ~/workspace/SmartResearch-HQ
bash scripts/bootstrap-local.sh   # .env / backend venv / frontend npm ci
bash scripts/install-git-hooks.sh # auto: WBS roadmap, PR checkboxes
```

### Recommended extensions

Cursor/VS Code will prompt for workspace extensions (`.vscode/extensions.json`).

| Extension | Use |
|-----------|-----|
| **Ruff** | Python lint / format |
| **Python** + **Pylance** | Types, venv |
| **ESLint** | TS / React lint |
| **Tailwind CSS IntelliSense** | Tailwind classes |
| **Docker** | compose editing |
| **GitHub Actions** | CI syntax |
| **EditorConfig** | Indent / EOL |

Format on save: `.vscode/settings.json` (Python → Ruff, TS → ESLint).

### Quality checks (before push)

```bash
bash scripts/ci-check.sh   # mirrors GitHub CI (Ruff + pytest + ESLint + build)
```

Git workflow: [docs/git-workflow.md](docs/git-workflow.md) — branch → PR → CI → squash merge.

Cursor / agent rules (`.cursor/`) are **local only** and not in the public clone — see [docs/agent-setup.md](docs/agent-setup.md).

---

## 開発環境

### 前提

| 項目 | バージョン / 備考 |
|------|-------------------|
| OS | **WSL Ubuntu**（Windows 上）。Git Bash + UNC パスは venv 破損の原因になるため使わない |
| Python | **3.12**（`python3.12-venv` パッケージが必要な場合あり） |
| Node.js | **20 LTS**（CI と同じ） |
| エディタ | **Cursor** または VS Code。リポジトリを WSL 側 `~/workspace/SmartResearch-HQ` で開く |
| Docker | 任意。`production` 検証（Postgres / Redis）時のみ |

### 初回セットアップ

```bash
cd ~/workspace/SmartResearch-HQ
bash scripts/bootstrap-local.sh   # .env / venv / npm ci
bash scripts/install-git-hooks.sh # 自動: WBS ロードマップ・PR チェックボックス
```

### 推奨拡張機能

`.vscode/extensions.json` 参照。保存時フォーマットは Ruff / ESLint。

### push 前の品質チェック

```bash
bash scripts/ci-check.sh
```

ブランチ運用: [docs/git-workflow.md](docs/git-workflow.md)

## Quick start (portfolio / Mock)

Postgres and Redis are **not** required.

```bash
bash scripts/bootstrap-local.sh
```

**Backend**

```bash
cd backend && source .venv/bin/activate
uvicorn app.main:app --reload --port 8000
```

`GET http://localhost:8000/api/v1/health` → `{ "status": "ok", "mode": "portfolio", ... }`

**Frontend**

```bash
cd frontend && npm run dev
```

Open http://localhost:3000 → enter a Shopee URL → review Amazon candidates.

**Production check (optional)**

```bash
cp .env.example .env
docker compose up -d postgres redis
```

---

## クイックスタート（portfolio / Mock）

**Postgres / Redis は不要**です。上記コマンドと同じ。

- API: http://localhost:8000/api/v1/health
- UI: http://localhost:3000 → Shopee URL 入力 → レビュー画面で候補選択

## Repository layout

```
├── docs/           # Design docs (+ docs/local/ gitignored notes)
├── frontend/       # Next.js dashboard & review UI
├── backend/        # FastAPI (Mock services in portfolio mode)
├── docker-compose.yml
└── scripts/        # bootstrap, CI, git hooks, automation
```

---

## リポジトリ構成

```
├── docs/           # 設計ドキュメント
├── frontend/       # Next.js ダッシュボード & レビュー UI
├── backend/        # FastAPI（portfolio 時は Mock）
├── docker-compose.yml
└── scripts/        # bootstrap, CI, 自動化スクリプト
```

## Documentation

- [Project plan](docs/プロジェクト計画書.md)
- [Requirements](docs/requirements.md)
- [Design (UI / MVP)](docs/design.md)
- [Architecture](docs/architecture.md)
- [Database schema](docs/database-schema.md)
- [API specification](docs/api-specification.md)
- [WBS roadmap](docs/wbs-roadmap.md) — task status auto-synced from artifacts
- [Git workflow](docs/git-workflow.md)

---

## ドキュメント

- [プロジェクト計画書](docs/プロジェクト計画書.md)
- [要件定義](docs/requirements.md)
- [設計（UI・MVP）](docs/design.md)
- [アーキテクチャ](docs/architecture.md)
- [DB スキーマ](docs/database-schema.md)
- [API 仕様](docs/api-specification.md)
- [WBS・ロードマップ](docs/wbs-roadmap.md) — 成果物から状態を自動更新
- [Git ブランチ運用](docs/git-workflow.md)

## Environment variables

| Variable | Description |
|----------|-------------|
| `APP_MODE` | `portfolio` (Mock) / `production` |
| `MATCHING_PROVIDER` | `amazon_search` (default) / `none` / `gemini` |
| `AMAZON_PAAPI_*` | PA-API 5.0 (production) |
| `GEMINI_API_KEY` | Only when using `gemini` (never commit) |
| `NEXT_PUBLIC_API_URL` | Frontend → API (default `http://localhost:8000/api/v1`) |

Copy from `.env.example` or run `bootstrap-local.sh`. `.env` is gitignored.

---

## 環境変数

| 変数 | 説明 |
|------|------|
| `APP_MODE` | `portfolio`（Mock） / `production` |
| `MATCHING_PROVIDER` | `amazon_search`（既定） / `none` / `gemini` |
| `AMAZON_PAAPI_*` | PA-API 5.0（production 時） |
| `GEMINI_API_KEY` | `gemini` 利用時のみ（コミット禁止） |
| `NEXT_PUBLIC_API_URL` | フロント → API |

## Roadmap

Phase checkboxes sync from [docs/wbs-roadmap.md](docs/wbs-roadmap.md) via `scripts/sync-wbs-roadmap.py` (runs on pre-commit).

- [x] **Phase 1** — Design, monorepo, docs alignment
- [x] **Phase 2** — Playwright, Amazon search, Sheets, workers
- [x] **Phase 3** — Job polling, Redis health, manual ASIN UI
- [ ] **Phase 4** — Public demo, Vercel deploy

---

## ロードマップ

`pre-commit` で WBS 表と連動してチェックが自動更新されます。

- [x] **Phase 1** — 設計・モノレポ・docs 整合
- [x] **Phase 2** — Playwright / Amazon 検索 / Sheets / ワーカー
- [x] **Phase 3** — 進捗ポーリング・Redis 本接続・手動 ASIN UI
- [ ] **Phase 4** — 公開デモ・Vercel デプロイ

## Automation (no manual steps)

| Trigger | What runs |
|---------|-----------|
| `git commit` (pre-commit) | WBS roadmap + README phase checkboxes |
| `git push` (post-push) | Create PR if missing; sync PR CI checkboxes |
| `bash scripts/ci-check.sh` | Roadmap sync + local CI mirror |
| GitHub CI (on PR) | `sync-pr-checkboxes` job when backend/frontend pass |

---

## 自動化（手動不要）

| タイミング | 内容 |
|------------|------|
| `git commit` | WBS ロードマップ + README フェーズチェック |
| `git push` | PR 自動作成・CI チェックボックス同期 |
| `ci-check.sh` | ロードマップ同期 + ローカル CI |
| GitHub CI | PR 本文の CI チェックを自動 `[x]` |

## License

Private / portfolio use. Portfolio edition omits scraping internals and proprietary prompts.

---

## ライセンス

Private / Portfolio 用途に応じて運用。表版ではスクレイピング回避・プロンプト等のコア実装は非公開。
