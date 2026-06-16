# ADR 0008: AI guardrails and production readiness

- **Status**: Accepted
- **Date**: 2026-05-31

## Context

SmartResearch-HQ is developed with heavy AI assistance. Without explicit guardrails, agents tend to:

- Add unverified PyPI/npm packages or deprecated APIs (hallucinated dependencies).
- Grow monolithic modules that mix HTTP, domain logic, and I/O, increasing defect rate and review cost.
- Implement mutating endpoints and workers that **double-apply** side effects on retry (network, queue redelivery).
- Rely on stdout or generic exceptions, making production incidents hard to diagnose.

Existing ADR 0006 covers **security standards**; ADR 0007 covers **YAGNI, fail-fast, testability, and Why-not-What**. Neither fully addresses **AI-specific workflow constraints** or **operational readiness** (idempotency, structured observability).

Portfolio mode still benefits: mock services should not corrupt state on double-submit; reviewers evaluate whether the author understands production trade-offs.

## Decision

Adopt four **AI Guardrails & Production Readiness** principles, summarized in [CONTEXT.md § System Architecture & Constraints](../../CONTEXT.md) and expanded in [docs/agents/ai-production-readiness.md](../agents/ai-production-readiness.md):

1. **Strict dependency control** — No new external package or deprecated API adoption without **explicit human approval** documented in the PR or issue. Agents must propose name, version, purpose, and alternatives; never invent package names.

2. **Context management & SRP** — Enforce single responsibility per module. When a file approaches **~300 lines** or mixes layers (route + domain + infrastructure), **propose a split before** adding more logic.

3. **Idempotency** — All side-effecting API operations and async job steps must be safe under at-least-once delivery. Use idempotency keys, conditional updates, natural keys, or deduplication tables as appropriate. Illegal state transitions must fail fast (aligns with ADR 0007).

4. **Observability** — Use structured logging (key fields: `job_id`, `status`, `mode`, exception type). Include enough context to debug without secrets. Important transitions and errors must not rely on bare print or silent catch-all handlers.

Implementation backlog: [ai-production-rollout-tasks.md](../agents/ai-production-rollout-tasks.md). Code changes may land in follow-up PRs.

## Alternatives considered

- **Fold into ADR 0007 only:** Rejected — 0007 targets portfolio *code quality*; dependency approval and idempotency are *process + ops* concerns that deserve separate indexing.
- **Cursor user rules only:** Rejected — not visible in public clone or to hiring reviewers.
- **Mandate OpenTelemetry + new logging library immediately:** Rejected — violates dependency control; start with stdlib logging + structured fields; revisit after human approval.
- **Hard CI fail at 300 lines:** Rejected — too noisy for legacy files; prefer WARN + tracked refactor tasks (A2.x in rollout tasks).

## Consequences

- Agents refuse to `pip install` / `npm install` new packages until the user approves.
- PRs touching POST/PUT/DELETE or worker tasks should mention idempotency strategy in Summary.
- Refactors for oversized files may be proposed without feature scope creep (YAGNI still applies to *abstractions*, not to *splitting tangled code*).
- Security guardrails (0006) still prohibit logging secrets; observability must redact tokens and PII.

## Related

- [0006](./0006-security-guardrails-public-standards.md) — OWASP / IPA / static analysis
- [0007](./0007-engineering-principles-for-agents.md) — YAGNI, fail-fast, testability, Why
- [CONTEXT.md](../../CONTEXT.md) — canonical short form
- [ai-production-readiness.md](../agents/ai-production-readiness.md) — operational detail (not duplicated here)
