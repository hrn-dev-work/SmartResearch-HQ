# SmartResearch-HQ

Cross-border e-commerce research: scrape Shopee seller SOLD listings, match Amazon ASIN candidates, human review, optional Sheets export. One codebase; `APP_MODE=portfolio` (demo) vs `APP_MODE=production` (workers + Postgres + Redis).

Detailed specs live under `docs/`. This file is the **domain glossary**, **security guardrails**, **engineering principles**, **AI guardrails**, and **implementation traps** for agents — not a spec, not a scratch pad.

Agent index: [docs/agents/README.md](docs/agents/README.md).

---

## Domain Language

**Research job**:
A single end-to-end run from Shopee shop URL input through scrape, candidate matching, review, and optional export. Persisted as `research_jobs` (production) or in-memory/mock (portfolio).
_Avoid_: calling it "task", "session", or "project" in API names.

**Shop URL**:
The Shopee seller storefront URL pasted on the dashboard (MVP: one URL only, no bulk upload).
_Avoid_: assuming product-level URLs; scraping targets seller SOLD inventory.

**Scrape / scraping**:
Playwright-driven extraction of SOLD products from the shop. Job state `SCRAPING`; failures → `SCRAPE_FAILED`.
_Avoid_: treating scrape as synchronous in the API handler — work is queued in production.

**Candidate matching**:
Map each Shopee line item to up to N Amazon `AmazonCandidate` records (`asin`, `url`, `title`, `confidence`). Provider is pluggable (`MATCHING_PROVIDER`; default `amazon_search` = PA-API title search).
_Avoid_: assuming Gemini-only; do not hard-code a single matcher in routes or UI.

**AmazonCandidate**:
One proposed ASIN match for a scraped item. Review UI lists candidates per item; operator Select or Reject.
_Avoid_: auto-selecting highest confidence without human action (see ADR 0003).

**Review / human-in-the-loop**:
Mandatory confirmation step before export. Job reaches `AWAITING_REVIEW` when candidates are ready.
_Avoid_: skipping review in portfolio demos — even mock data should exercise Select/Reject.

**Export**:
Push approved rows toward Google Sheets (production) or log-only count/toast (portfolio; no service account in public repo).
_Avoid_: expecting real Spreadsheet writes in portfolio E2E.

**AI_INFERENCE** (status):
Legacy name for **candidate matching in progress**. Not Gemini-specific.
_Avoid_: renaming in DB/API without migration plan; document meaning in UI copy.

**Portfolio mode**:
`APP_MODE=portfolio` — `MockResearchService`, no Postgres/Redis required, fast path to review for public demo.
_Avoid_: forking the frontend; mode is env-driven on the same Next.js app.

**Production mode**:
`APP_MODE=production` — FastAPI enqueues ARQ/Celery workers, PostgreSQL persistence, real Playwright + matchers.
_Avoid_: importing production-only deps in portfolio code paths without guards.

---

## Relationships

- 1 **Research job** → many scraped **line items** → many **AmazonCandidate** rows per item (max N).
- 1 selected candidate per item → **APPROVED** / **REJECTED** → optional **EXPORTED**.

State machine (see `docs/architecture.md` §3):

`PENDING → SCRAPING → AI_INFERENCE → AWAITING_REVIEW → APPROVED/REJECTED → EXPORTED`

Failure branches: `SCRAPE_FAILED`, `AI_FAILED` (retry/DLQ in production).

---

## System Architecture & Constraints

| Layer | Stack | Notes |
|-------|-------|-------|
| Frontend | Next.js, TypeScript, Tailwind | Dashboard + review; polls job status (SSE later) |
| API | FastAPI | `/research`, `/review`, mode switch via env |
| Queue | Redis + ARQ | Production async scrape/match |
| DB | PostgreSQL | `research_jobs` history |
| Scrape | Playwright | Shopee seller SOLD |
| Match | Pluggable | `amazon_search` default (PA-API) |

- **No auth in MVP** (ADR 0002): do not add Authorization middleware without explicit reopen.
- **WSL Ubuntu** for dev on Windows; avoid Git Bash on UNC paths (see `docs/agent-shell-fix.md`).
- **i18n**: UI strings live in frontend message modules; keep EN/JA doc headings paired per `docs/doc-conventions.md`.

**AI guardrails & production readiness** (ADR 0008). Full guidance: [docs/agents/ai-production-readiness.md](docs/agents/ai-production-readiness.md).

| Principle | One-line rule |
|-----------|----------------|
| **Strict dependency control** | No new PyPI/npm/system packages without explicit human approval in PR or issue. |
| **Context management & SRP** | Split files approaching ~300 lines or mixing route + domain + I/O before adding logic. |
| **Idempotency** | Mutating APIs and worker steps must be safe under at-least-once delivery. |
| **Observability** | Structured logs (`job_id`, `status`, `APP_MODE`); no secrets or bare `print` in hot paths. |

---

## Security Guardrails

Read [docs/agents/security.md](docs/agents/security.md) before adding API surface, env vars, user input, or auth.

- Never commit secrets (`.env`, API keys, tokens, service accounts). Use `.env.example` with key names only.
- Server-only secrets stay on the backend. **`NEXT_PUBLIC_*` is public** — never expose PA-API, Gemini, DB, or Sheets credentials there.
- Validate and reject bad input at boundaries (HTTP handlers, CLI). Do not pass untrusted strings to SQL, shell, or file paths.
- Do not log secrets, full auth headers, or PII-heavy payloads.
- Security linter / CodeQL / secret-audit warnings are **merge blockers** unless explicitly waived with an ADR.

Rollout tasks (GitHub settings, Dependabot, rate limits): [docs/agents/security-rollout-tasks.md](docs/agents/security-rollout-tasks.md).

### 5. Public security standards / 公的セキュリティ規格への準拠

Code generation and design must prioritize:

- **OWASP Top 10 (latest)** — eliminate injection, broken auth, misconfiguration, SSRF, and related classes at implementation time.
- **IPA「安全なウェブサイトの作り方」** — implement XSS, SQL injection, CSRF, and session handling mitigations at the code level, not as afterthoughts.
- **Static analysis & type safety** — code that triggers security linters, Snyk, or GitHub Advanced Security alerts, or that relies on TypeScript `any` / unsafe casts without documented exception, is treated as non-compliant. Fix or record an ADR with explicit waiver.

See ADR [0006](docs/adr/0006-security-guardrails-public-standards.md).

---

## Engineering Principles (agents & contributors)

Portfolio reviewers and production operators should see **simple, testable, well-reasoned** backend code. Full guidance: [docs/agents/engineering-principles.md](docs/agents/engineering-principles.md). ADR: [0007](docs/adr/0007-engineering-principles-for-agents.md).

| Principle | One-line rule |
|-----------|----------------|
| **YAGNI + AHA** | Ship the simplest code that meets today's requirement; abstract only after the **Rule of Three** (same logic duplicated ≥3 times). |
| **Fail-fast** | Guard clauses at boundaries; throw early on invalid state — never silently continue. |
| **Testability** | Business logic separate from DB/API/Playwright; prefer pure functions and inject dependencies for pytest. |
| **Why, not What** | ADRs and non-obvious comments document **decision rationale** and rejected alternatives — not a restatement of the code. |

---

## Common Ambiguities

- `AI_INFERENCE` sounds like LLM work — it is **matching**, any provider.
- Portfolio export **button** is real UX; backend write is **log-only** (ADR 0005).
- `confidence` is matching score, not auto-approval permission.
- Frontend `APP_MODE` / API base URL must align with backend mode for E2E.

---

## Architecture decisions

See `docs/adr/README.md`. Accepted ADRs: 0001–0008 map to design and agent policy. Do not re-litigate without explicit user request.

---

## Flagged ambiguities (open)

- Bulk shop URL intake (post-MVP).
- SSE vs polling default for progress (Phase 3).
- Auth provider choice before production multi-user.

---

# SmartResearch-HQ（日本語）

越境 EC リサーチ: Shopee セラー SOLD 出品をスクレイプし、Amazon ASIN 候補とマッチング、人間レビュー、任意で Sheets エクスポート。単一コードベース。`APP_MODE=portfolio`（デモ）と `APP_MODE=production`（ワーカー + Postgres + Redis）。

詳細仕様は `docs/` 配下。本ファイルはエージェント向けの **ドメイン用語集**、**セキュリティガードレール**、**工学原則**、**AI ガードレール**、**実装の落とし穴** — 仕様書でもメモ帳でもない。

エージェント索引: [docs/agents/README.md](docs/agents/README.md)。

---

## ドメイン言語

**Research job（リサーチジョブ）**:
Shopee ショップ URL 入力からスクレイプ、候補マッチング、レビュー、任意エクスポートまでの一連の実行。本番は `research_jobs` に永続化、portfolio は in-memory / モック。
_Avoid_: API 名で "task"、"session"、"project" と呼ばない。

**Shop URL（ショップ URL）**:
ダッシュボードに貼る Shopee セラー店舗 URL（MVP: 1 URL のみ、一括アップロードなし）。
_Avoid_: 商品 URL 前提にしない。スクレイプ対象はセラー SOLD 在庫。

**Scrape / scraping（スクレイプ）**:
Playwright による店舗 SOLD 商品の抽出。ジョブ状態 `SCRAPING`。失敗時 `SCRAPE_FAILED`。
_Avoid_: API ハンドラで同期スクレイプ扱いにしない — 本番はキュー投入。

**Candidate matching（候補マッチング）**:
各 Shopee 行を最大 N 件の Amazon `AmazonCandidate`（`asin`, `url`, `title`, `confidence`）に対応付け。プロバイダは差し替え可能（`MATCHING_PROVIDER`、既定 `amazon_search` = PA-API タイトル検索）。
_Avoid_: Gemini 専用とみなさない。route / UI にマッチャーを直書きしない。

**AmazonCandidate**:
スクレイプ品目に対する ASIN 候補 1 件。レビュー UI で品目ごとに一覧し、オペレータが Select / Reject。
_Avoid_: 人の操作なしに最高 confidence を自動選択しない（ADR 0003）。

**Review / human-in-the-loop（レビュー）**:
エクスポート前の必須確認。候補準備完了で `AWAITING_REVIEW`。
_Avoid_: portfolio デモでレビューを飛ばさない — モックでも Select/Reject を通す。

**Export（エクスポート）**:
承認行を Google Sheets へ（本番）、またはログのみ + トースト（portfolio。公開リポにサービスアカウントなし）。
_Avoid_: portfolio E2E で実 Spreadsheet 書き込みを期待しない。

**AI_INFERENCE**（ステータス）:
**候補マッチング進行中**のレガシー名。Gemini 専用ではない。
_Avoid_: DB/API で無計画に改名しない。UI 文言で意味を明示。

**Portfolio mode（portfolio モード）**:
`APP_MODE=portfolio` — `MockResearchService`、Postgres/Redis 不要、公開デモ向けレビュー短縮パス。
_Avoid_: フロントを分岐フォークしない。同一 Next.js アプリで env 切替。

**Production mode（本番モード）**:
`APP_MODE=production` — FastAPI が ARQ/Celery ワーカーへ投入、PostgreSQL 永続化、実 Playwright + マッチャー。
_Avoid_: ガードなしで portfolio パスに本番専用依存を import しない。

---

## 関係

- 1 **Research job** → 複数スクレイプ **line items** → 品目あたり複数 **AmazonCandidate**（最大 N）。
- 品目あたり 1 候補選択 → **APPROVED** / **REJECTED** → 任意で **EXPORTED**。

ステートマシン（`docs/architecture.md` §3）:

`PENDING → SCRAPING → AI_INFERENCE → AWAITING_REVIEW → APPROVED/REJECTED → EXPORTED`

失敗分岐: `SCRAPE_FAILED`、`AI_FAILED`（本番はリトライ / DLQ）。

---

## システム構成と制約

| 層 | スタック | 備考 |
|----|----------|------|
| Frontend | Next.js, TypeScript, Tailwind | ダッシュボード + レビュー。ジョブ状態はポーリング（将来 SSE） |
| API | FastAPI | `/research`, `/review`、env でモード切替 |
| Queue | Redis + ARQ | 本番の非同期スクレイプ / マッチ |
| DB | PostgreSQL | `research_jobs` 履歴 |
| Scrape | Playwright | Shopee セラー SOLD |
| Match | プラガブル | 既定 `amazon_search`（PA-API） |

- **MVP に認証なし**（ADR 0002）: 明示的な再オープンなしに Authorization ミドルウェアを足さない。
- **Windows 開発は WSL Ubuntu**; UNC 上の Git Bash を避ける（`docs/agent-shell-fix.md`）。
- **i18n**: UI 文言はフロントの message モジュール。公開 md の見出しは `docs/doc-conventions.md` に従い EN/JA を揃える。

**AI ガードレールと本番運用準備**（ADR 0008）。詳細: [docs/agents/ai-production-readiness.md](docs/agents/ai-production-readiness.md)。

| 原則 | 一行ルール |
|------|------------|
| **厳格な依存関係管理** | PR / issue で人間の明示承認なしに PyPI/npm/システムパッケージを追加しない。 |
| **コンテキスト管理と SRP** | 約 300 行または route + ドメイン + I/O 混在時は追記前に分割。 |
| **冪等性** | 変更系 API とワーカーは at-least-once 配信でも安全であること。 |
| **可観測性** | 構造化ログ（`job_id`, `status`, `APP_MODE`）。秘密や hot path の bare `print` 禁止。 |

---

## セキュリティガードレール

API 追加、env、ユーザー入力、認証の前に [docs/agents/security.md](docs/agents/security.md) を読む。

- 秘密情報をコミットしない（`.env`、API キー、トークン、サービスアカウント）。`.env.example` はキー名のみ。
- サーバー専用秘密はバックエンドのみ。**`NEXT_PUBLIC_*` は公開** — PA-API、Gemini、DB、Sheets 資格情報を載せない。
- 境界（HTTP ハンドラ、CLI）で不正入力を拒否。信頼できない文字列を SQL、シェル、ファイルパスへ渡さない。
- 秘密、認証ヘッダ全文、PII 多めのペイロードをログに出さない。
- セキュリティリンター / CodeQL / secret-audit の警告は ADR 免除なしでは **マージブロッカー**。

ロールアウト（GitHub 設定、Dependabot、レート制限）: [docs/agents/security-rollout-tasks.md](docs/agents/security-rollout-tasks.md)。

### 5. Public security standards / 公的セキュリティ規格への準拠

コード生成と設計では以下を優先する:

- **OWASP Top 10（最新）** — 実装時点で injection、認証破綻、設定ミス、SSRF 等を排除。
- **IPA「安全なウェブサイトの作り方」** — XSS、SQLi、CSRF、セッション対策を後付けではなくコードレベルで実装。
- **静的解析と型安全** — セキュリティリンター、Snyk、GitHub Advanced Security、TypeScript `any` / 不安全キャスト（文書化された例外なし）は非準拠。修正するか ADR で免除。

ADR [0006](docs/adr/0006-security-guardrails-public-standards.md) を参照。

---

## 工学原則（エージェントとコントリビュータ）

portfolio レビュアーと本番オペレータには **単純でテスト可能で筋の通った** バックエンドを見せる。詳細: [docs/agents/engineering-principles.md](docs/agents/engineering-principles.md)。ADR: [0007](docs/adr/0007-engineering-principles-for-agents.md)。

| 原則 | 一行ルール |
|------|------------|
| **YAGNI + AHA** | 今日の要件を満たす最も単純なコード。**Rule of Three**（同一ロジックが 3 回以上）後に抽象化。 |
| **Fail-fast** | 境界でガード。不正状態は早期に例外 — 黙って継続しない。 |
| **Testability** | ビジネスロジックを DB/API/Playwright から分離。純関数と pytest 向け DI。 |
| **Why, not What** | ADR と非自明コメントは **判断理由** と却下した代替案 — コードの言い換えではない。 |

---

## よくある曖昧さ

- `AI_INFERENCE` は LLM に聞こえるが、実体は **マッチング**（任意プロバイダ）。
- portfolio のエクスポート **ボタン** は実 UX。バックエンド書き込みは **ログのみ**（ADR 0005）。
- `confidence` はマッチングスコアであり、自動承認の許可ではない。
- フロントの `APP_MODE` / API ベース URL はバックエンドモードと E2E で一致させる。

---

## アーキテクチャ決定

`docs/adr/README.md` を参照。Accepted ADR: 0001–0008 が設計とエージェント方針に対応。ユーザー明示なしに再議論しない。

---

## 未解決の曖昧さ（オープン）

- ショップ URL 一括取り込み（MVP 後）。
- 進捗の SSE とポーリングの既定（Phase 3）。
- 本番マルチユーザー前の認証プロバイダ選定。
