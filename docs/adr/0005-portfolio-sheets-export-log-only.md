# ADR 0005: Portfolio Sheets export is log-only

- **Status**: Accepted
- **Date**: 2026-05-31

## Context

A public portfolio repo cannot ship Google service-account credentials. Export UX still needs to demonstrate the workflow.

## Decision

In portfolio mode, the export button runs the same UI path but persists only a count/toast (log-only), not a real Spreadsheet write.

## Consequences

- Production mode owns real Sheets integration and secrets.
- E2E tests assert toast/count, not external Sheet rows.

See [design.md §11 D7](../design.md).
