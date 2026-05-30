# Deployment guide — Portfolio mode (Vercel + Render)

Public demo runs **without** PostgreSQL, Redis, or API keys. Set only the variables below in each platform’s dashboard.

See also: [render.yaml](../render.yaml) (backend Blueprint), [README](../README.md).

---

## Overview

| Layer | Platform | Role |
|-------|----------|------|
| Frontend | [Vercel](https://vercel.com) | Next.js static/SSR UI |
| Backend | [Render](https://render.com) | FastAPI (`APP_MODE=portfolio`, in-memory Mock) |

**Order:** Deploy backend first → copy Render URL → set `NEXT_PUBLIC_API_URL` on Vercel → set `ALLOWED_ORIGINS` on Render with your Vercel URL(s).

---

## Vercel (frontend)

Project root: **`frontend/`** (set as Root Directory in Vercel project settings).

| Variable | Required | Example | Notes |
|----------|----------|---------|-------|
| `NEXT_PUBLIC_API_URL` | Yes | `https://smartresearch-api.onrender.com/api/v1` | Render web service URL + `/api/v1`. No trailing slash. |

<!-- Production-only — not needed for portfolio demo:
| `NEXT_PUBLIC_*` (other) | No | — | — |
-->

**Build defaults (typical):**

- Framework: Next.js  
- Build command: `npm run build` (default)  
- Output: default  

Redeploy after changing `NEXT_PUBLIC_*` (values are baked in at build time).

---

## Render (backend)

Use [render.yaml](../render.yaml) or create a **Web Service** manually:

| Setting | Value |
|---------|--------|
| Root directory | `backend` |
| Runtime | Python |
| Build command | `pip install -r requirements.txt` |
| Start command | `uvicorn app.main:app --host 0.0.0.0 --port $PORT` |

| Variable | Required | Example | Notes |
|----------|----------|---------|-------|
| `APP_MODE` | Yes | `portfolio` | In-memory Mock; no DB/Redis. |
| `ALLOWED_ORIGINS` | Yes (after Vercel) | `https://your-app.vercel.app` | Comma-separated frontend origin(s). Localhost is always allowed for dev. |

<!-- Production-only — omit for portfolio:
| `DATABASE_URL` | — | — | PostgreSQL (production) |
| `REDIS_URL` | — | — | ARQ worker queue |
| `MATCHING_PROVIDER` | — | `amazon_search` | PA-API / Gemini |
| `AMAZON_PAAPI_*` | — | — | Amazon Product Advertising API |
| `GEMINI_API_KEY` | — | — | Optional matcher |
| `GOOGLE_SHEETS_CREDENTIALS_PATH` | — | — | Service account JSON path |
| `GOOGLE_SHEET_ID` | — | — | Target spreadsheet |
-->

**Health check:** `GET /api/v1/health` should return `200`.

**Free tier:** Render spins down after idle; first request may take ~30s (cold start).

---

## Post-deploy checklist

- [ ] Render `/api/v1/health` returns OK  
- [ ] Vercel app loads and can start a research job  
- [ ] Browser network tab: API calls go to Render URL (not `localhost`)  
- [ ] No CORS errors (verify `ALLOWED_ORIGINS` matches Vercel URL exactly, including `https://`)  
- [ ] Review → export flow completes on demo fixtures  

---

## Local parity

```bash
# Backend
cd backend && APP_MODE=portfolio uvicorn app.main:app --reload --port 8000

# Frontend
cd frontend && NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1 npm run dev
```

Optional local CORS test with production-like origins:

```bash
ALLOWED_ORIGINS=https://your-app.vercel.app uvicorn app.main:app --port 8000
```
