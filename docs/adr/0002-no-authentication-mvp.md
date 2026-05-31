# ADR 0002: No authentication in MVP

- **Status**: Accepted
- **Date**: 2026-05-31

## Context

Portfolio viewers and early internal pilots do not need tenant isolation yet. Adding Auth0 (or similar) before core research/review UX is stable would slow the demo path.

## Decision

No authentication or authorization headers in MVP. Restrict exposure via deployment (portfolio host, CORS dev origins) until Phase 4 production hardening.

## Consequences

- All API routes are open on the deployed URL; do not store secrets in client bundles.
- Revisit before multi-tenant or PII-heavy workflows.

See [design.md §11 D2](../design.md).
