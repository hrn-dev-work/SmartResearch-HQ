# SmartResearch-HQ

Cross-border e-commerce research: scrape Shopee seller SOLD listings, match Amazon ASIN candidates, human review, optional Sheets export. One codebase; `APP_MODE=portfolio` (demo) vs `APP_MODE=production` (workers + Postgres + Redis).

Detailed specs live under `docs/`. This file is the **domain glossary**, **security guardrails**, **engineering principles**, and **implementation traps** for agents — not a spec, not a scratch pad.

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
Map each Shopee line item to up to N Amazon `AmazonCandidate` records (`asin`, `url`, `title`, `confidence`). Provider is pluggable (`MATCHING_PROVIDER`).
_Avoid_: assuming Gemini-only; default path is PA-API title search.

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
| Match | Pluggable | PA-API default |

- **No auth in MVP** (ADR 0002): do not add Authorization middleware without explicit reopen.
- **WSL Ubuntu** for dev on Windows; avoid Git Bash on UNC paths (see `docs/agent-shell-fix.md`).
- **i18n**: UI strings live in frontend message modules; keep EN/JA doc headings paired per `docs/doc-conventions.md`.

---

## Security Guardrails

Read [docs/agents/security.md](docs/agents/security.md) before adding API surface, env vars, user input, or auth.

- Never commit secrets (`.env`, API keys, tokens, service accounts). Use `.env.example` with key names only.
- Server-only secrets stay on the backend. **`NEXT_PUBLIC_*` is public** — never expose PA-API, Gemini, DB, or Sheets credentials there.
- Validate and reject bad input at boundaries (HTTP handlers, CLI). Do not pass untrusted strings to SQL, shell, or file paths.
- Do not log secrets, full auth headers, or PII-heavy payloads.
- Security linter / CodeQL / secret-audit warnings are **merge blockers** unless explicitly waived with an ADR.

Rollout tasks (GitHub settings, Dependabot, rate limits): [docs/agents/security-rollout-tasks.md](docs/agents/security-rollout-tasks.md).

---

## 5. 公的セキュリティ規格への準拠 / Public security standards

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

See `docs/adr/README.md`. Accepted ADRs: 0001–0007 map to design and agent policy. Do not re-litigate without explicit user request.

---

## Flagged ambiguities (open)

- Bulk shop URL intake (post-MVP).
- SSE vs polling default for progress (Phase 3).
- Auth provider choice before production multi-user.
