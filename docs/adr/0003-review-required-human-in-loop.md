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

## Alternatives considered

- **Auto-export above a confidence threshold:** Rejected — wrong ASIN on a Shopee listing is direct business risk; confidence scores are not trustworthy enough alone.
- **Optional review skip for internal operators:** Rejected — undermines the same trust model portfolio reviewers evaluate.
- **Batch approve without per-candidate inspection:** Rejected — hides the core human-in-the-loop product surface.

See [design.md §11 D4](../design.md) and [requirements.md](../requirements.md).
