# Tech stack policy — agent guide

Operational companion to [docs/tech-stack-policy.md](../tech-stack-policy.md). Decision record: [ADR 0009](../adr/0009-layered-tech-stack-policy.md).

## When to read

- Bootstrapping a **new** repository
- User asks for “standard stack” or proposes Laravel / shadcn on **this** repo
- Choosing tests or layer boundaries on a greenfield Profile A app

## Profile selection (30 seconds)

| Signal | Profile |
|--------|---------|
| Playwright scrape, Redis queue, LLM/PA-API, job state machine | **B — FastAPI** |
| Users, roles, billing, CRUD admin, Laravel team velocity | **A — Laravel** |
| Unsure | Default **A** for internal business tools; **B** for automation pipelines |

Document the choice in the new repo’s `README.md` and `CONTEXT.md` (one table row + link to policy).

## This repository (SmartResearch-HQ)

**Always Profile B.** Do not:

- Add Laravel, PHP, or shadcn/ui without user explicitly reopening ADR 0009 + design §2
- Rewrite backend to match a Profile A template

**Do** align new work with:

- [backend-python.mdc](../../.cursor/rules/backend-python.mdc) — layers, `APP_MODE`, matchers
- [de-ai-ui.mdc](../../.cursor/rules/de-ai-ui.mdc) — no card stacks, no UI libraries
- [api-specification.md](../api-specification.md) — contract before code

## New Profile A repo (checklist)

1. `frontend/`: Next.js App Router, Tailwind, shadcn/ui, `messages/ja.ts` + `en.ts`, `middleware.ts` for locale
2. `backend/` or separate API repo: Laravel API-only, Sanctum/Passport when auth ships
3. `docs/api-specification.md` or OpenAPI export from Laravel (Scribe / OpenAPI generator)
4. `NEXT_PUBLIC_API_URL` on Vercel; CORS on API
5. CI: Pint/PHPStan or Larastan + Pest + one Playwright smoke
6. First ADR if auth provider or multi-tenant model is fixed early

## New Profile B repo (checklist)

1. Mirror SmartResearch-HQ layout: `frontend/`, `backend/`, `render.yaml` optional
2. `app/services/` for domain; scrapers/workers in infrastructure paths only
3. Env-driven mocks for public demo if portfolio matters (see ADR 0001 pattern)
4. CI: Ruff + pytest; sync-api-types script if TS client generated from OpenAPI
5. Document queue/Redis in architecture.md — not optional if async jobs exist

## Conflicts to escalate (do not improvise)

| User request | Response |
|--------------|----------|
| “Use Laravel on SmartResearch-HQ” | Cite ADR 0009 + policy §4; offer new Profile A repo or ADR reopen |
| “Add shadcn here” | Cite de-ai-ui + policy Profile B; offer Profile A project or custom components |
| “Unit tests only” | Cite testing-istqb + policy §6; add integration + E2E on critical path |
| “Full DDD with repositories everywhere” | Cite ADR 0007 Rule of Three; services layer only until third repetition |

## Links

| Doc | Role |
|-----|------|
| [tech-stack-policy.md](../tech-stack-policy.md) | Human-readable Must / Choose (EN/JA) |
| [ADR 0009](../adr/0009-layered-tech-stack-policy.md) | Why layered policy exists |
| [engineering-principles.md](./engineering-principles.md) | YAGNI, fail-fast, testability |
| [deployment-guide.md](../deployment-guide.md) | Vercel + Render env vars |
