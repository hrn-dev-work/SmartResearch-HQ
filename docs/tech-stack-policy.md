# Organization tech stack policy

Canonical policy for **all web projects** in this workspace. SmartResearch-HQ follows **Profile B** (see §4). Rationale and rejected alternatives: [ADR 0009](./adr/0009-layered-tech-stack-policy.md).

---

## 1. Purpose

- One **shared baseline** so agents, CI, and deploy patterns stay predictable.
- **No forced backend rewrite** of pipeline-heavy repos (scraping, queues, AI).
- Clear **Must vs Choose** so new Laravel SaaS and existing FastAPI pipelines coexist.

---

## 2. Layer 1 — Must (every project)

| Area | Standard | Notes |
|------|----------|-------|
| Frontend | React, **Next.js App Router**, **TypeScript**, **Tailwind CSS** | Same app shell patterns; env via `NEXT_PUBLIC_*` only for public values |
| Integration | **FE/BE fully separated**; **REST**; **OpenAPI** (or equivalent spec) as contract source | Frontend talks only through a single API layer (e.g. `lib/api.ts`) |
| Database | **PostgreSQL** when relational persistence is needed | Skip DB for static/demo-only apps |
| Hosting | **Vercel** (frontend) + **Render** or **Railway** (API and managed Postgres) | Match [deployment-guide.md](./deployment-guide.md) patterns |
| UI languages | **ja / en** message dictionaries + cookie `locale`; middleware geo default | See [design.md §2.6](./design.md) and global `ui-i18n-locale` rule |
| TypeScript | Strict types; **avoid `any`** and unsafe casts | Security / quality bar: ADR 0006 |
| Domain code | Business rules in **services / domain**; HTTP layer thin | Practical layering per ADR 0007 — not full DDD ceremony |
| Tests | **Component** + **component integration** + **critical System E2E** | ISTQB-aligned; unit-only is insufficient. See [testing-istqb rule](../.cursor/rules/testing-istqb.mdc) |
| Secrets | Server keys on backend only; `.env.example` names only | [docs/agents/security.md](./agents/security.md) |

---

## 3. Layer 2 — Choose (per project profile)

Pick **one profile** at project start and document it in README + `CONTEXT.md`.

### Profile A — Business SaaS

**When:** CRUD-heavy apps, admin panels, auth, subscriptions, form workflows.

| Area | Choice |
|------|--------|
| Backend | **PHP 8.x**, **Laravel** (API stack) |
| UI components | **shadcn/ui** allowed (forms, tables, dialogs) |
| Async work | Laravel queues + Horizon when needed |
| Tests | PHPUnit or Pest; API feature tests; Playwright for main user flows |

### Profile B — Data / automation / AI pipeline

**When:** Scraping, batch jobs, ML/LLM integrations, pluggable providers, long-running workers.

| Area | Choice |
|------|--------|
| Backend | **Python 3.11+**, **FastAPI**, Pydantic v2 |
| Workers | Redis + ARQ/Celery (or equivalent) when async pipelines exist |
| Browser automation | Playwright (Python) in infrastructure layer |
| UI components | **Custom Tailwind**; avoid generic UI libraries unless ADR reopens | 
| Tests | pytest + Ruff; Playwright E2E for portfolio/demo paths |

**SmartResearch-HQ = Profile B** (FastAPI, Playwright, Redis, dual `APP_MODE`).

---

## 4. This repository (SmartResearch-HQ)

| Layer | Implementation |
|-------|----------------|
| Frontend | Next.js 16, TypeScript, Tailwind — [frontend/](../frontend/) |
| API | FastAPI — [backend/](../backend/) |
| Contract | [api-specification.md](./api-specification.md) |
| Deploy | Vercel + Render — [deployment-guide.md](./deployment-guide.md), [render.yaml](../render.yaml) |
| DDD style | `app/services/`, Protocol/factory — [backend-python.mdc](../.cursor/rules/backend-python.mdc) |
| Dual mode | ADR 0001 — portfolio Mock vs production workers |

Do **not** migrate this repo to Laravel to satisfy Profile A; new business SaaS repos use Profile A instead.

---

## 5. DDD and architecture (all profiles)

**Do:**

- Ubiquitous language shared across API, UI, and docs (`CONTEXT.md`).
- Keep business rules out of route/controller handlers.
- Inject dependencies at composition roots for testability.

**Do not (ADR 0007):**

- Mandate repositories, event buses, or bounded contexts before a third repetition (Rule of Three).
- Add speculative interfaces “for later.”

Laravel mapping: `app/Services/` or Actions + thin controllers.  
FastAPI mapping: `app/services/` + `app/api/` routes + `deps.py`.

---

## 6. Testing standard (all profiles)

| ISTQB level | Purpose | Required when |
|-------------|---------|---------------|
| Component | Single module behavior | Non-trivial domain logic |
| Component integration | HTTP + service + fakes | New API endpoints |
| System | End-to-end on staging/mock | Primary user journeys (e.g. research → review → export) |
| System integration | Real external systems | Before production cutover |
| Acceptance | Requirements sign-off | Milestone / release |

**Must:** fix regressions with both a targeted test and a smoke path on critical flows.

---

## 7. New project checklist

1. Choose **Profile A or B**; link this doc from README.
2. Scaffold frontend: Next.js + Tailwind + `messages/{ja,en}.ts`.
3. Define OpenAPI first; generate or sync client types where applicable.
4. Set deploy: Vercel root = `frontend/`; API on Render/Railway with health check.
5. Add CI: lint + unit/integration + one E2E smoke.
6. Record irreversible choices in `docs/adr/` when they affect public behavior or hiring review.

---

## 8. Quick reference — proposal vs policy

| Item | Org Must | Profile A | Profile B (this repo) |
|------|----------|-----------|------------------------|
| Next.js + TS + Tailwind | Yes | Yes | Yes |
| shadcn/ui | — | Yes (default) | No (de-AI / minimal UI) |
| Laravel | — | Yes | No |
| FastAPI | — | No | Yes |
| PostgreSQL | When needed | Yes | Yes (production) |
| Vercel + Render/Railway | Yes | Yes | Yes |
| REST + OpenAPI | Yes | Yes | Yes |
| Practical services layer | Yes | Yes | Yes |
| Unit tests only | **No** — include E2E | Pest/PHPUnit + E2E | pytest + Playwright |

---

# 組織技術スタック方針

本ワークスペース内の **すべての Web プロジェクト** に適用する正本。SmartResearch-HQ は **プロファイル B**（§4 参照）。理由と却下案: [ADR 0009](./adr/0009-layered-tech-stack-policy.md)。

---

## 1. 目的

- エージェント・CI・デプロイを **共通 baseline** で揃える。
- スクレイピング・キュー・AI 系の既存リポを **バックエンドごと書き換えない**。
- **Must / Choose** を明示し、新規 Laravel SaaS と既存 FastAPI パイプラインを共存させる。

---

## 2. レイヤ 1 — Must（全プロジェクト）

| 領域 | 標準 | 補足 |
|------|------|------|
| フロント | React、**Next.js App Router**、**TypeScript**、**Tailwind CSS** | 公開値のみ `NEXT_PUBLIC_*` |
| 連携 | **FE/BE 完全分離**、**REST**、**OpenAPI**（同等 spec）を契約の正本 | フロントは API 層（例: `lib/api.ts`）経由のみ |
| DB | 永続化が必要なら **PostgreSQL** | 静的デモのみは省略可 |
| ホスティング | **Vercel**（FE）+ **Render** または **Railway**（API / DB） | [deployment-guide.md](./deployment-guide.md) に準拠 |
| UI 言語 | **ja / en** 辞書 + cookie `locale`、middleware で地域既定 | [design.md §2.6](./design.md) |
| TypeScript | 厳密な型、**`any` 回避** | ADR 0006 |
| ドメイン | **services / domain** に業務ロジック、HTTP 層は薄く | ADR 0007 の実用 DDD（本格 DDD 儀式は不要） |
| テスト | **Component** + **結合** + **主要 System E2E** | 単体のみは不十分 |
| 秘密情報 | サーバー鍵は BE のみ、`.env.example` はキー名のみ | [security.md](./agents/security.md) |

---

## 3. レイヤ 2 — Choose（プロジェクトプロファイル）

開始時に **1 プロファイル** を選び、README と `CONTEXT.md` に記載する。

### プロファイル A — 業務 SaaS

**向くケース:** CRUD、管理画面、認証、課金、フォーム中心。

| 領域 | 選択 |
|------|------|
| バックエンド | **PHP 8.x**、**Laravel**（API） |
| UI | **shadcn/ui** 可 |
| 非同期 | 必要なら Laravel Queue + Horizon |
| テスト | PHPUnit / Pest、API feature、主要フロー Playwright |

### プロファイル B — データ / 自動化 / AI パイプライン

**向くケース:** スクレイピング、バッチ、ML/LLM、差し替え可能プロバイダ、長時間ワーカー。

| 領域 | 選択 |
|------|------|
| バックエンド | **Python 3.11+**、**FastAPI**、Pydantic v2 |
| ワーカー | 非同期パイプラインがある場合 Redis + ARQ/Celery 等 |
| ブラウザ自動化 | Playwright（Python）を infrastructure 層に |
| UI | **カスタム Tailwind**、汎用 UI ライブラリは ADR 再検討まで非推奨 |
| テスト | pytest + Ruff、デモ経路 Playwright E2E |

**SmartResearch-HQ = プロファイル B**（FastAPI、Playwright、Redis、`APP_MODE` 二刀流）。

---

## 4. 本リポジトリ（SmartResearch-HQ）

| 層 | 実装 |
|----|------|
| フロント | Next.js 16、TypeScript、Tailwind — [frontend/](../frontend/) |
| API | FastAPI — [backend/](../backend/) |
| 契約 | [api-specification.md](./api-specification.md) |
| デプロイ | Vercel + Render — [deployment-guide.md](./deployment-guide.md) |
| レイヤ | `app/services/`、Protocol — [backend-python.mdc](../.cursor/rules/backend-python.mdc) |
| 二刀流 | ADR 0001 — portfolio Mock / production workers |

Profile A 合わせのため **Laravel へ移行しない**。新規業務 SaaS は別リポで Profile A を使う。

---

## 5. DDD とアーキテクチャ（全プロファイル）

**する:**

- ユビキタス言語（`CONTEXT.md`）を API / UI / docs で統一。
- route / controller に業務ルールを書かない。
- テスト容易性のため composition root で DI。

**しない（ADR 0007）:**

- 3 回目の重複前の Repository / イベントバス / 境界コンテキストの義務化。
- 「将来のため」の speculative な interface。

Laravel: `app/Services/` または Actions + 薄い controller。  
FastAPI: `app/services/` + `app/api/` + `deps.py`。

---

## 6. テスト標準（全プロファイル）

| ISTQB レベル | 目的 | いつ必須か |
|--------------|------|------------|
| Component | 単一モジュール | 非自明なドメインロジック |
| Component integration | HTTP + service + fake | 新規 API |
| System | mock/staging 上 E2E | 主要ユーザージャーニー |
| System integration | 外部システム実接続 | 本番切替前 |
| Acceptance | 要件充足 | マイルストーン |

**Must:** 不具合修正時は pinpoint テスト + 重要経路のスモークの両方。

---

## 7. 新規プロジェクトチェックリスト

1. **Profile A / B** を選び README から本 doc へリンク。
2. フロント雛形: Next.js + Tailwind + `messages/{ja,en}.ts`。
3. OpenAPI を先に定義。型同期があれば CI に組み込む。
4. デプロイ: Vercel `frontend/`、API は Render/Railway + health check。
5. CI: lint + unit/integration + E2E スモーク 1 本。
6. 不可逆な選択は `docs/adr/` に記録。

---

## 8. 早見表 — 当初提案 vs 本ポリシー

| 項目 | Org Must | Profile A | Profile B（本 repo） |
|------|----------|-----------|----------------------|
| Next.js + TS + Tailwind | ○ | ○ | ○ |
| shadcn/ui | — | ○（既定） | ×（de-AI / 最小 UI） |
| Laravel | — | ○ | × |
| FastAPI | — | × | ○ |
| PostgreSQL | 必要時 | ○ | ○（本番） |
| Vercel + Render/Railway | ○ | ○ | ○ |
| REST + OpenAPI | ○ | ○ | ○ |
| services 層 | ○ | ○ | ○ |
| 単体テストのみ | **×**（E2E 含む） | Pest + E2E | pytest + Playwright |
