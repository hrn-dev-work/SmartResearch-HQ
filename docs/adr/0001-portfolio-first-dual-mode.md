# ADR 0001: Portfolio-first dual mode

- **Status**: Accepted
- **Date**: 2026-05-31

## Context

SmartResearch-HQ ships one codebase with `APP_MODE=portfolio` (public demo) and `APP_MODE=production` (real scrape/match/export). Portfolio E2E is the top priority for reviewers and deploy smoke tests.

## Decision

Implement portfolio mode first: mock research can jump to `AWAITING_REVIEW` without Postgres/Redis. Production mode adds workers, PA-API matching, and Sheets export behind the same API surface.

## Consequences

- Demo badge and `MockResearchService` are first-class, not throwaway.
- Env-driven mode switch; no separate forked frontend.

## Alternatives considered

- **Separate demo and production repositories:** Rejected — duplicate API/UI maintenance and drift risk.
- **Production mode first:** Rejected — blocks portfolio deploy, E2E smoke tests, and reviewer access without credentials.
- **Feature flags only (no `APP_MODE`):** Rejected — weaker boundary for workers, secrets, and mock vs real I/O.

See [design.md §11 D1](../design.md) and [architecture.md §4](../architecture.md).
