# ADR 0003: Review required (human-in-the-loop)

- **Status**: Accepted
- **Date**: 2026-05-31

## Context

Wrong Amazon ASIN on a Shopee listing is a direct business risk. Fully automated export without confirmation undermines trust.

## Decision

Every candidate requires explicit Select/Reject in the review UI. No auto-export on high confidence alone.

## Consequences

- Review screen is a product surface, not an admin afterthought.
- Job states must reach `AWAITING_REVIEW` before export actions.

See [design.md §11 D4](../design.md) and [requirements.md](../requirements.md).
