# SmartResearch-HQ

**[Demo App](https://smart-research-hq.vercel.app)** — live portfolio (Vercel + Render, `APP_MODE=portfolio`)

Cross-border e-commerce research automation: scrape Shopee SOLD listings, match Amazon ASIN candidates, human review, export to spreadsheet. Built as a production-grade pipeline with a **public-safe demo edition** for hiring and client proposals.

---

## Why two modes in one codebase

| Mode | Audience | Runtime |
|------|----------|---------|
| **Portfolio** (this demo) | Recruiters, clients, reviewers | In-memory Mock — no Postgres, Redis, or API keys |
| **Production** (private ops) | Real cross-border EC workflows | Playwright scraping, Redis + ARQ workers, pluggable matching (PA-API / Gemini), Google Sheets |

The same FastAPI + Next.js monorepo switches behavior via `APP_MODE`. The portfolio build removes infrastructure cost and secret-handling risk while preserving the full UI flow (research → review → export). Production adds async job processing and live integrations without forking the frontend.

Use the in-app **「このデモについて」** link in the header for a concise system overview.

---

## Tech stack

- **Frontend:** Next.js 16, TypeScript, Tailwind CSS
- **Backend:** FastAPI, Pydantic v2
- **Portfolio infra:** Vercel (UI) + Render (API) — see [deployment guide](docs/deployment-guide.md)
- **Production infra:** PostgreSQL 16, Redis 7, Playwright, Google Sheets API

---

## Quick start (local, portfolio)

Postgres and Redis are **not** required.

```bash
bash scripts/bootstrap-local.sh

# Terminal 1 — API
cd backend && source .venv/bin/activate
uvicorn app.main:app --reload --port 8000

# Terminal 2 — UI
cd frontend && npm run dev
```

Open http://localhost:3000 → enter a Shopee shop URL → review candidates → export.

Health: `GET http://localhost:8000/api/v1/health` → `{ "status": "ok", "mode": "portfolio", ... }`

---

## Deploy (portfolio)

1. Apply [render.yaml](render.yaml) on Render (`APP_MODE=portfolio`).
2. Deploy `frontend/` to Vercel; set `NEXT_PUBLIC_API_URL` to your Render API base + `/api/v1`.
3. Set `ALLOWED_ORIGINS` on Render to your Vercel URL(s).

Full checklist: **[docs/deployment-guide.md](docs/deployment-guide.md)**  
Troubleshooting (404, CORS, CLI): **[docs/deployment-troubleshooting.md](docs/deployment-troubleshooting.md)**

One-command redeploy: `bash scripts/portfolio-vercel-deploy.sh redeploy`

---

## Repository layout

```
├── docs/           # Design & architecture
├── frontend/       # Next.js dashboard & review UI
├── backend/        # FastAPI (Mock services in portfolio mode)
├── render.yaml     # Render Blueprint (portfolio API)
├── docker-compose.yml
└── scripts/        # bootstrap, CI, smoke tests
```

---

## Documentation

| Doc | Contents |
|-----|----------|
| [Project plan](docs/プロジェクト計画書.md) | Goals & scope |
| [Architecture](docs/architecture.md) | Two-mode design, data flow |
| [Design](docs/design.md) | UI principles |
| [API specification](docs/api-specification.md) | REST contract |
| [Deployment guide](docs/deployment-guide.md) | Vercel / Render env vars |

---

## Development

### Prerequisites

| Item | Notes |
|------|-------|
| OS | **WSL Ubuntu** recommended on Windows (avoid Git Bash + UNC paths) |
| Python | 3.12 |
| Node.js | 20 LTS |
| Docker | Optional — production verification only |

```bash
bash scripts/ci-check.sh   # Ruff + pytest + ESLint + build (mirrors CI)
```

Production verification (optional): copy `.env.example` → `.env`, then `docker compose up -d postgres redis` with `APP_MODE=production`.

### Key environment variables (portfolio)

| Variable | Where | Description |
|----------|-------|-------------|
| `APP_MODE` | Backend | `portfolio` (Mock) or `production` |
| `NEXT_PUBLIC_API_URL` | Frontend | API base URL, e.g. `http://localhost:8000/api/v1` |
| `ALLOWED_ORIGINS` | Backend | Comma-separated CORS origins for deployed frontend |

See `.env.example` for production-only variables (PA-API, Gemini, Sheets).

---

## Roadmap

- [x] Phase 1 — Design, monorepo, docs
- [x] Phase 2 — Scraping, matching, Sheets, workers
- [x] Phase 3 — Job polling, manual ASIN UI
- [x] Phase 4 — Portfolio deploy config, About demo UI, deployment docs

---

## License

Private / portfolio use. The portfolio edition omits scraping internals and proprietary prompts.

---

越境 EC（Shopee 等）の商品リサーチ・名寄せを **スクレイピング + 候補マッチング + Human-in-the-loop** で自動化するシステムです。表（Portfolio）と裏（Production）の二刀流構成により、公開デモと実運用を同一リポジトリで維持しています。

- デモ: 上記 **[Demo App](https://smart-research-hq.vercel.app)** リンク
- ローカル起動: 上記 Quick start 参照
- デプロイ手順: [docs/deployment-guide.md](docs/deployment-guide.md)
- 障害対応: [docs/deployment-troubleshooting.md](docs/deployment-troubleshooting.md)
