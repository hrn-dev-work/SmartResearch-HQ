# Production local setup（裏版・非公開）

Public portfolio demo uses `APP_MODE=portfolio` only. **Production mode is for local or private infrastructure** — do not deploy it to the public Vercel demo URL.

See [architecture.md](architecture.md) §4 (二刀流) and [wbs-roadmap.md](wbs-roadmap.md) Phase 2.

---

## Quick start

```bash
bash scripts/start-production-local.sh
```

Then edit **`.env`** (never commit):

```env
APP_MODE=production
MATCHING_PROVIDER=amazon_search   # default; or none | gemini
# AMAZON_PAAPI_* — required for amazon_search matching
```

**Three terminals (full stack):**

```bash
# 1 — API
cd backend && source .venv/bin/activate
APP_MODE=production uvicorn app.main:app --reload --port 8000

# 2 — Worker
cd backend && source .venv/bin/activate
arq app.workers.settings.WorkerSettings

# 3 — UI
cd frontend && NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1 npm run dev
```

---

## Smoke tests

| Command | Needs |
|---------|--------|
| `bash scripts/smoke-m2.sh` | Docker, Playwright, PA-API for full pipeline |
| `SKIP_PIPELINE=1 bash scripts/smoke-m2.sh` | Scrape only (no PA-API) |
| `python -m app.cli scrape --url "..." --limit 5` | Playwright |

---

## APIs (production)

| Variable | Required when |
|----------|----------------|
| `DATABASE_URL`, `REDIS_URL` | Always (docker-compose defaults OK locally) |
| `AMAZON_PAAPI_*` | `MATCHING_PROVIDER=amazon_search` (default) |
| `GEMINI_API_KEY` | `MATCHING_PROVIDER=gemini` only (optional) |
| `GOOGLE_SHEETS_*` | Real spreadsheet export |

Gemini is **not** required for the default path ([design.md](design.md) D5).

---

## 日本語

- 表デモ: [deployment-guide.md](deployment-guide.md)
- 詳細メモ（Git 外）: 開発者マシンの `docs/local/production-overview.md`
