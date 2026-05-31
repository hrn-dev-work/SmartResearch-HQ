# SmartResearch-HQ

Cross-border e-commerce research: scrape Shopee seller SOLD listings, match Amazon ASIN candidates, human review, optional Sheets export. One codebase; `APP_MODE=portfolio` (demo) vs `APP_MODE=production` (workers + Postgres + Redis).

Detailed specs live under `docs/`. This file is the **domain glossary** and **implementation traps** for agents — not a spec, not a scratch pad.

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

## Common Ambiguities

- `AI_INFERENCE` sounds like LLM work — it is **matching**, any provider.
- Portfolio export **button** is real UX; backend write is **log-only** (ADR 0005).
- `confidence` is matching score, not auto-approval permission.
- Frontend `APP_MODE` / API base URL must align with backend mode for E2E.

---

## Architecture decisions

See `docs/adr/README.md`. Accepted ADRs: 0001–0005 map to `docs/design.md` §11 (D1, D2, D4, D5, D7). Do not re-litigate without explicit user request.

---

## Flagged ambiguities (open)

- Bulk shop URL intake (post-MVP).
- SSE vs polling default for progress (Phase 3).
- Auth provider choice before production multi-user.
