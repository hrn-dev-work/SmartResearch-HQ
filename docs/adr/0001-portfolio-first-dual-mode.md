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

See [design.md §11 D1](../design.md) and [architecture.md §4](../architecture.md).
