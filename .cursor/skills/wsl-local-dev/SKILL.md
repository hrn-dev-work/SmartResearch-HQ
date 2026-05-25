---
name: wsl-local-dev
description: >-
  SmartResearch-HQ local dev on WSL Ubuntu (not Git Bash): Python venv, uvicorn,
  Next.js, bootstrap scripts, Mock API mode, APP_MODE=portfolio, token-saving
  agent workflow. Use for setup, terminal commands, docker, npm, pip, venv errors,
  localhost port confusion, or when the user runs dev servers without reading AGENTS.md.
summary: WSL Ubuntu で API(:8000)/UI(:3000) を起動。venv・ポート・Playwright のトラブル対応。
user-prompt: ローカルで SmartResearch-HQ を起動して。WSL Ubuntu、portfolio（Mock）で health が ok になるまで確認して。
category: 環境
disable-model-invocation: false
---

# SmartResearch-HQ — WSL ローカル開発

## 必須: シェル

| プロンプト | 判定 |
|-----------|------|
| `haruna@HARUNA:~/workspace/...$` | ✅ WSL bash で実行 |
| `MINGW64 //wsl.localhost/...` | ❌ 使わない。Ubuntu ターミナルへ誘導 |

Git Bash + UNC パスで `venv` / `pip` を触ると壊れる（`activate` 不在・I/O error）。

## クイック起動（このリポジトリ）

```bash
# 初回のみ（ensurepip 不足時）
sudo apt install -y python3.12-venv

cd ~/workspace/SmartResearch-HQ
bash scripts/bootstrap-local.sh
```

**ターミナル 1 — API (:8000)**

```bash
cd ~/workspace/SmartResearch-HQ/backend
source .venv/bin/activate
uvicorn app.main:app --reload --port 8000
```

**ターミナル 2 — UI (:3000)**

```bash
cd ~/workspace/SmartResearch-HQ/frontend
npm run dev
```

検証: `curl -s http://127.0.0.1:8000/api/v1/health` → `{"status":"ok","mode":"portfolio"}`

## このプロジェクトの前提

- `APP_MODE=portfolio` → **Postgres/Redis 不要**（インメモリ Mock）
- API: `http://localhost:8000/api/v1`
- フロント: `frontend/.env.local` の `NEXT_PUBLIC_API_URL`

## venv トラブル時

```bash
cd ~/workspace/SmartResearch-HQ/backend
rm -rf .venv
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

`which pip` が `.venv/bin/pip` であること。

## Playwright スクレイプ（Phase 2）

```bash
cd ~/workspace/SmartResearch-HQ/backend
source .venv/bin/activate
playwright install chromium

# libnspr4.so 等のエラー時 — sudo では venv 内の playwright をフルパス指定
sudo ~/workspace/SmartResearch-HQ/backend/.venv/bin/playwright install-deps chromium

python -m app.cli scrape --url "https://shopee.sg/shop/..." --limit 5
```

`sudo playwright` だけだと **command not found**（playwright は venv 内のみ）。

## エージェントの制約

- `sudo` はユーザーが WSL で実行（非対話では不可）
- WSL 内から `wsl` コマンドは不要
- ビルドエラーは **パスでプロジェクトを特定**（`taxport` 等の別アプリが :3000 で動いていることがある）
- 完了前に health / ポートを確認

## 他リポジトリ（taxport 等）

Tailwind `@apply` で custom class not found → `tailwind.config.js` + `postcss.config.js` で config を明示（`.ts` が PostCSS から読めないことがある）。
