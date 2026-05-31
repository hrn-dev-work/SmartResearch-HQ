# ADR 0007: Engineering principles for agents and portfolio review

- **Status**: Accepted
- **Date**: 2026-05-31

## Context

`APP_MODE=portfolio` exists so recruiters and technical interviewers can evaluate the system without production credentials. They judge **robustness, clarity of trade-offs, and test discipline** — not feature count. AI-assisted development often over-abstracts (violating YAGNI/AHA), defers error handling, produces hard-to-test handlers, and documents *what* the code does instead of *why*.

## Decision

Adopt four explicit principles for all agent-generated and human-reviewed code:

1. **YAGNI + AHA (Rule of Three)** — simplest implementation for current requirements; extract shared abstractions only after three concrete duplications.
2. **Fail-fast + guard clauses** — reject invalid input and state at boundaries; avoid deep nesting and silent continuation.
3. **Design for testability** — separate business logic from infrastructure; inject dependencies; prefer pure functions; cover non-trivial logic with pytest.
4. **Why, not What** — ADRs and selective comments capture decision rationale and rejected alternatives; do not narrate obvious code.

Canonical agent text: [docs/agents/engineering-principles.md](../agents/engineering-principles.md). Summary in [CONTEXT.md](../../CONTEXT.md).

## Alternatives considered

- **Rely on user rules only:** Rejected — not visible in public repo or to reviewers without Cursor.
- **Enforce via linter only:** Rejected — complexity and test structure need human/agent judgment; CI stays behavioral (pytest, Ruff, ESLint).
- **Full DDD / clean architecture mandate:** Rejected — over-engineering for current MVP; violates YAGNI.

## Consequences

- PR reviewers expect ADR updates when introducing new irreversible patterns.
- Agents should refuse speculative interfaces unless user explicitly requests extensibility.
- Backend changes that only add happy-path code without boundary checks should fail review.

Portfolio signal: README + ADRs explain *why* dual-mode and human review exist — interviewers should not read every file to understand intent.
