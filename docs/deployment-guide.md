# Deployment guide — Portfolio mode (Vercel + Render)

Public demo runs **without** PostgreSQL, Redis, or API keys. Set only the variables below in each platform’s dashboard.

See also: [render.yaml](../render.yaml) (backend Blueprint), [README](../README.md), [deployment-troubleshooting.md](deployment-troubleshooting.md).

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

Redeploy after changing `NEXT_PUBLIC_*` (values are baked in at build time).

**Build defaults (typical):** Next.js, `npm run build`, default output.

### Public access (portfolio demo)

Share the **Production URL** only (e.g. `https://smart-research-hq.vercel.app`). Do **not** share hash preview URLs (`https://smart-research-xxxxx-….vercel.app`) with recruiters — they may require Vercel login.

1. **Settings → Deployment Protection** → turn **Vercel Authentication** **OFF** → Save  
   (Optional: leave protection on for Preview only; Production should stay public.)
2. After a bad deploy, the browser may cache a **404**. Test in a **private/incognito** window or hard-reload (Ctrl+F5 / Cmd+Shift+R).
3. Aliasing to the production domain can lag a few minutes after deploy; use **Visit** on the latest Production deployment if the alias still fails.

**One-command ops:** `bash scripts/portfolio-vercel-deploy.sh redeploy` (frontend). Troubleshooting: [deployment-troubleshooting.md](deployment-troubleshooting.md).

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

**Health check:** `GET /api/v1/health` should return `200`.

**Free tier:** Render spins down after idle; first request may take ~30s (cold start).

Production-only variables (Postgres, Redis, PA-API, Gemini, Sheets) are **not** required for portfolio mode.

---

## Post-deploy checklist

- [ ] Render `/api/v1/health` returns OK
- [ ] **Production URL** opens in a private/incognito window (no Vercel login)
- [ ] Deployment Protection: Vercel Authentication **off** for public demo (or Preview-only)
- [ ] Vercel app loads and can start a research job
- [ ] Browser network tab: API calls go to Render URL (not `localhost`)
- [ ] No CORS errors (`ALLOWED_ORIGINS` matches Vercel URL exactly, including `https://`)
- [ ] Review → export flow completes on demo fixtures
- [ ] JA / EN toggle works; API URL is correct in both locales

---

## Local parity

```bash
# Backend
cd backend && APP_MODE=portfolio uvicorn app.main:app --reload --port 8000

# Frontend
cd frontend && NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1 npm run dev
```

Optional local CORS test:

```bash
ALLOWED_ORIGINS=https://your-app.vercel.app uvicorn app.main:app --port 8000
```

---

# デプロイ手順 — Portfolio モード（Vercel + Render）

公開デモは **PostgreSQL・Redis・API キー不要**。各プラットフォームのダッシュボードで、下表の環境変数だけ設定する。

関連: [render.yaml](../render.yaml)（バックエンド Blueprint）、[README](../README.md)、[deployment-troubleshooting.md](deployment-troubleshooting.md)。

---

## 概要

| 層 | プラットフォーム | 役割 |
|----|------------------|------|
| フロント | [Vercel](https://vercel.com) | Next.js（UI） |
| API | [Render](https://render.com) | FastAPI（`APP_MODE=portfolio`、インメモリ Mock） |

**順序:** Render で API を先にデプロイ → URL を控える → Vercel に `NEXT_PUBLIC_API_URL` → Render に `ALLOWED_ORIGINS`（Vercel の URL）

---

## Vercel（フロント）

プロジェクトの **Root Directory** を **`frontend/`** に設定する。

| 変数 | 必須 | 例 | 備考 |
|------|------|-----|------|
| `NEXT_PUBLIC_API_URL` | はい | `https://smartresearch-api.onrender.com/api/v1` | Render の URL + `/api/v1`。末尾スラッシュなし |

`NEXT_PUBLIC_*` はビルド時に埋め込まれるため、変更後は **再デプロイ** が必要。

**ビルド（典型）:** Next.js、`npm run build`、出力はデフォルト。

### 公開アクセス（ポートフォリオデモ）

共有するのは **Production URL のみ**（例: `https://smart-research-hq.vercel.app`）。ハッシュ付き Preview URL（`https://smart-research-xxxxx-….vercel.app`）は Vercel ログインが必要なことがあり、採用担当者には渡さない。

1. **Settings → Deployment Protection** → **Vercel Authentication** を **OFF** → Save  
   （Preview のみ保護、Production は公開、でも可）
2. デプロイ失敗時の **404 がブラウザにキャッシュ** されることがある。**シークレット / プライベートウィンドウ** またはスーパーリロード（Ctrl+F5 / Cmd+Shift+R）で確認
3. 本番ドメインへのエイリアス反映に **数分** かかることがある。alias がダメなら最新 Production デプロイの **Visit** で確認

**ワンコマンド:** `bash scripts/portfolio-vercel-deploy.sh redeploy`（フロント）。障害対応: [deployment-troubleshooting.md](deployment-troubleshooting.md)

---

## Render（API）

[render.yaml](../render.yaml) の Blueprint、または **Web Service** を手動作成:

| 項目 | 値 |
|------|-----|
| Root directory | `backend` |
| Runtime | Python |
| Build command | `pip install -r requirements.txt` |
| Start command | `uvicorn app.main:app --host 0.0.0.0 --port $PORT` |

| 変数 | 必須 | 例 | 備考 |
|------|------|-----|------|
| `APP_MODE` | はい | `portfolio` | インメモリ Mock。DB/Redis 不要 |
| `ALLOWED_ORIGINS` | Vercel 後 | `https://your-app.vercel.app` | フロントの origin をカンマ区切り。localhost は常に許可 |

**ヘルスチェック:** `GET /api/v1/health` が `200`

**無料枠:** アイドル後にスリープ。初回アクセスは **約 30 秒**（コールドスタート）のことがある

Portfolio モードでは Postgres / Redis / PA-API / Gemini / Sheets は **不要**。

---

## デプロイ後チェックリスト

- [ ] Render の `/api/v1/health` が OK
- [ ] **Production URL** がシークレットウィンドウで開く（Vercel ログイン不要）
- [ ] Deployment Protection: 公開デモなら Vercel Authentication **OFF**（または Preview のみ保護）
- [ ] Vercel で画面が開き、リサーチを開始できる
- [ ] 開発者ツールの Network で API が Render 向き（`localhost` ではない）
- [ ] CORS エラーなし（`ALLOWED_ORIGINS` が Vercel URL と完全一致、`https://` 含む）
- [ ] レビュー → エクスポートまで完走（Mock フィクスチャ）
- [ ] **JA / EN** 切替と API 接続が問題ない

---

## ローカルとの対応

```bash
# API
cd backend && APP_MODE=portfolio uvicorn app.main:app --reload --port 8000

# フロント
cd frontend && NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1 npm run dev
```

本番に近い CORS 確認:

```bash
ALLOWED_ORIGINS=https://your-app.vercel.app uvicorn app.main:app --port 8000
```
