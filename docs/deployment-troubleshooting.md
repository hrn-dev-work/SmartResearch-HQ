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

After `agent-run`, read `.agent-local/latest.log` and `.agent-local/latest.exit`. **Agents run these commands** — do not ask the user to paste them.

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
| Agent Shell empty output on Windows | Use `bash scripts/agent-run.sh -- …` and read `.agent-local/latest.log` |
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

`agent-run` 後は **`.agent-local/latest.log`** / **`.agent-local/latest.exit`** を Read する。**エージェントが実行する**（ユーザーにコマンド実行を頼まない）。

---

## Vercel CLI

| 事象 | 対処 |
|------|------|
| `isn't linked to a project` | `cd frontend && npx vercel link --yes --project smart-research-hq` |
| `vercel link` が `.env.local` を上書き | 復元: `echo 'NEXT_PUBLIC_API_URL=https://smartresearch-api.onrender.com/api/v1' > frontend/.env.local` |
| `--name` が効かず旧プロジェクトにデプロイ | `.vercel/` を削除して再 link、またはダッシュボードで新規プロジェクト |
| `git stash` 後に `.vercel/project.json` がない | `vercel link` または `bash scripts/portfolio-vercel-deploy.sh redeploy` |

---

## Render

| 事象 | 対処 |
|------|------|
| API は OK だがブラウザで CORS | **smartresearch-api → Environment → `ALLOWED_ORIGINS`** = `https://smart-research-hq.vercel.app`（origin 完全一致、末尾スラッシュなし） |
| CORS の設定場所 | サービスの **Environment**（Environment Group ではない） |
| 初回 API が約 30 秒 | 無料枠のコールドスタート — 正常 |

ヘルスチェック URL（フルパス）:

```
https://smartresearch-api.onrender.com/api/v1/health
```

ルート URL だけだと `{"detail":"Not Found"}` — 想定どおり。

---

## Git（ローカル）

| 事象 | 対処 |
|------|------|
| `pull` が `scripts/dev.sh` でブロック | `origin/main` で削除済み。`rm -f scripts/dev.sh` して pull、または `bash scripts/portfolio-vercel-deploy.sh full` |
| Windows でエージェント Shell が空 | `bash scripts/agent-run.sh -- …` で `.agent-local/latest.log` を Read |
| `main` から直接 push | `bash scripts/agent-push.sh portfolio-docs-deploy` またはブランチを切る |

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

## デモ URL

- フロント: https://smart-research-hq.vercel.app  
- API: https://smartresearch-api.onrender.com/api/v1  
- ショップ URL（Mock）: `https://shopee.sg/demo-shop`（何でも可）
