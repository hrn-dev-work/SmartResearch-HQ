# ADR 0009: Layered tech stack policy (org-wide Must vs project Choose)

- **Status**: Accepted
- **Date**: 2026-06-20

## Context

We want a consistent development environment across multiple projects while **SmartResearch-HQ** already ships FastAPI, Playwright workers, Redis queues, and portfolio dual-mode (`APP_MODE`). A single backend language (e.g. Laravel everywhere) would force a full rewrite of accepted ADRs (0001, 0004), CI, and Render deployment without improving scrape/match/queue workloads.

Frontend, API contract discipline, PostgreSQL, and Vercel + PaaS hosting already align with a proposed org standard. UI kit and “full DDD” wording need guardrails so they do not conflict with ADR 0007 (YAGNI; no full clean-architecture mandate).

## Decision

Adopt a **two-layer policy** documented in [docs/tech-stack-policy.md](../tech-stack-policy.md):

1. **Must (all web projects)** — Next.js App Router, TypeScript, Tailwind, FE/BE separation via REST + OpenAPI, PostgreSQL when persistence is required, Vercel (frontend) + Render or Railway (API/DB), UI i18n via message dictionaries + cookie locale, practical domain layering (services; thin controllers/routes), TypeScript without `any`, tests at Component + integration + critical System E2E (ISTQB-aligned).

2. **Choose (per project profile)** — Backend runtime and UI component strategy:
   - **Profile A — Business SaaS** (CRUD, auth, billing, admin): Laravel API (PHP 8.x), optional shadcn/ui.
   - **Profile B — Data / automation / AI pipeline** (scraping, queues, ML integrations): FastAPI (Python 3.11+), custom Tailwind UI per design system (de-AI rules where applicable).

**SmartResearch-HQ is Profile B** and remains on FastAPI; it is not an exception to be “fixed later.” New Laravel projects do not require changing this repository.

## Consequences

- New repos can share frontend, deploy, and API-contract conventions without a backend rewrite of existing pipeline projects.
- Agents and reviewers use one policy doc; profile selection is explicit at project bootstrap.
- shadcn/ui is allowed on Profile A only by default; Profile B repos keep minimal UI libraries unless an ADR reopens the choice.
- Org onboarding must record **profile + stack** in README / CONTEXT (link to policy).

## Alternatives considered

- **Laravel for all projects including SmartResearch-HQ:** Rejected — high migration cost; loses native Playwright/ARQ/Python matcher ecosystem; breaks render.yaml, ci-check.sh, and ADR 0001/0004 implementations.
- **FastAPI for all projects including future admin SaaS:** Rejected — Laravel’s auth, queues (Horizon), and CRUD ergonomics are stronger for typical business apps; forcing Python everywhere reduces team velocity where PHP is the better fit.
- **No written org standard (ad hoc per repo):** Rejected — duplicates agent rules, causes stack drift, and makes cross-project Cursor rules ambiguous.
- **Full DDD / clean architecture as org mandate:** Rejected — same rationale as ADR 0007; over-engineering for MVP-scale work.

## Related

- [docs/tech-stack-policy.md](../tech-stack-policy.md) — operational policy (EN/JA)
- ADR [0007](./0007-engineering-principles-for-agents.md) — practical layering, not full DDD
- ADR [0001](./0001-portfolio-first-dual-mode.md) — SmartResearch-HQ dual mode
