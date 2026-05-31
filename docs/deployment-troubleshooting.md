# Deployment troubleshooting — Portfolio (Vercel + Render)

Symptoms and fixes from the first public deploy (2026-05). See also [deployment-guide.md](deployment-guide.md).

---

## Quick commands (no manual typing)

| Goal | Command |
|------|---------|
| Redeploy frontend only | `bash scripts/portfolio-vercel-deploy.sh redeploy` |
| Full deploy (sync main + build) | `bash scripts/portfolio-vercel-deploy.sh` |
| Push docs / deploy notes | `bash scripts/agent-push.sh portfolio-docs-deploy` |
| Agent runs any script + log file | `bash scripts/agent-run.sh -- bash scripts/...` |

After `agent-run`, read `agent-cmd-output.txt` and `agent-cmd-exit.txt` in repo root.

---

## Vercel: 404 NOT_FOUND but deploy shows Ready

| Cause | Fix |
|-------|-----|
| **Browser cached an old 404** | Incognito / private window, or Ctrl+F5 (Cmd+Shift+R) |
| **Preview URL requires login** | Share **Production URL** only (`https://smart-research-hq.vercel.app`). Turn off **Settings → Deployment Protection → Vercel Authentication** for public demo |
| **Framework preset was Other** (first Git deploy) | **Settings → Build and Deployment → Framework: Next.js**, Output Directory override **OFF**, redeploy without cache. Or use CLI: `bash scripts/portfolio-vercel-deploy.sh redeploy` |
| **Root Directory + CLI cwd mismatch** | Either Root Directory **empty** and CLI from `frontend/`, or Root Directory **`frontend`** and CLI from repo root. Do not set `frontend` and run CLI inside `frontend/` |
| **Production alias lag** | Wait 2–5 min or open **Visit** on latest Production deployment |

**Signal:** Function Invocations stay **0** and every path returns Vercel `NOT_FOUND` → routing manifest not generated (usually Framework Other or wrong output directory).

---

## Vercel CLI

| Issue | Fix |
|-------|-----|
| `isn't linked to a project` | `cd frontend && npx vercel link --yes --project smart-research-hq` |
| `vercel link` overwrote `.env.local` | Restore: `echo 'NEXT_PUBLIC_API_URL=https://smartresearch-api.onrender.com/api/v1' > frontend/.env.local` |
| `--name` ignored, still deploys to old project | Delete `.vercel/` and link explicitly; or create new project in dashboard |
| `.vercel/project.json` missing after `git stash` | Re-run `vercel link` or `bash scripts/portfolio-vercel-deploy.sh redeploy` |

---

## Render

| Issue | Fix |
|-------|-----|
| API OK but browser CORS error | **smartresearch-api → Environment → `ALLOWED_ORIGINS`** = `https://smart-research-hq.vercel.app` (exact origin, no trailing slash) |
| Where to set CORS | Service **Environment**, not Environment Group |
| First API call slow (~30s) | Free tier cold start — normal |

Health check URL (full path):

```
https://smartresearch-api.onrender.com/api/v1/health
```

Root URL alone returns `{"detail":"Not Found"}` — that is expected.

---

## Git (local)

| Issue | Fix |
|-------|-----|
| `pull` blocked by `scripts/dev.sh` | File was removed on `origin/main`; `rm -f scripts/dev.sh` then pull, or run `bash scripts/portfolio-vercel-deploy.sh full` |
| Agent Shell empty output on Windows | Use `bash scripts/agent-run.sh -- …` and read `agent-cmd-output.txt` |
| Push from `main` | Use `bash scripts/agent-push.sh portfolio-docs-deploy` or create a branch first |

---

## Demo URL (current)

- **Frontend:** https://smart-research-hq.vercel.app  
- **API:** https://smartresearch-api.onrender.com/api/v1  
- **Mock shop URL (any):** `https://shopee.sg/demo-shop` — portfolio mode does not scrape live Shopee

---

# デプロイ障害 — Portfolio（Vercel + Render）

初回公開デプロイ（2026-05）で起きた事象のメモ。[deployment-guide.md](deployment-guide.md) も参照。

---

## ワンコマンド

| 目的 | コマンド |
|------|---------|
| フロント再デプロイのみ | `bash scripts/portfolio-vercel-deploy.sh redeploy` |
| main 同期 + ビルド + デプロイ | `bash scripts/portfolio-vercel-deploy.sh` |
| ドキュメントを push | `bash scripts/agent-push.sh portfolio-docs-deploy` |
| エージェント用（ログファイル出力） | `bash scripts/agent-run.sh -- bash scripts/...` |

`agent-run` 後はリポジトリ直下の `agent-cmd-output.txt` / `agent-cmd-exit.txt` を読む。

---

## Vercel: Ready なのに 404

| 原因 | 対処 |
|------|------|
| **ブラウザが 404 をキャッシュ** | シークレットウィンドウ / スーパーリロード |
| **Preview URL はログイン必須** | **Production URL** のみ共有。**Deployment Protection → Vercel Authentication OFF** |
| **Framework が Other のまま** | Framework **Next.js**、Output Directory override **OFF**、キャッシュなし再デプロイ。または `bash scripts/portfolio-vercel-deploy.sh redeploy` |
| **Root Directory と CLI の実行場所が二重** | Root 空 + `frontend/` から CLI、または Root `frontend` + リポジトリルートから CLI |

**目安:** Function Invocations が **0** のまま全パス 404 → ルーティング未生成（Framework Other 等）。

---

## Render / Git

- CORS → **`ALLOWED_ORIGINS`** = `https://smart-research-hq.vercel.app`（サービスの Environment）
- API ヘルス → `/api/v1/health` まで付ける
- `scripts/dev.sh` で pull 失敗 → ローカルファイル削除後 pull
- エージェントの Shell 空出力 → **`bash scripts/agent-run.sh -- …`**

---

## デモ URL

- フロント: https://smart-research-hq.vercel.app  
- API: https://smartresearch-api.onrender.com/api/v1  
- ショップ URL（Mock）: `https://shopee.sg/demo-shop`（何でも可）
