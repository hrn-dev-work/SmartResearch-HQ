# Architecture Decision Records

Accepted decisions for this repository. Agents: **do not re-litigate** an Accepted ADR unless the user explicitly asks to reopen it.

| ID | Title | Status |
|----|-------|--------|
| [0001](./0001-portfolio-first-dual-mode.md) | Portfolio-first dual mode | Accepted |
| [0002](./0002-no-authentication-mvp.md) | No authentication in MVP | Accepted |
| [0003](./0003-review-required-human-in-loop.md) | Review required (human-in-the-loop) | Accepted |
| [0004](./0004-pluggable-candidate-matching.md) | Pluggable candidate matching | Accepted |
| [0005](./0005-portfolio-sheets-export-log-only.md) | Portfolio Sheets export log-only | Accepted |
| [0006](./0006-security-guardrails-public-standards.md) | Security guardrails (OWASP / IPA) | Accepted |
| [0007](./0007-engineering-principles-for-agents.md) | Engineering principles (YAGNI, fail-fast, tests, Why) | Accepted |

## Template

Copy `0000-template.md` when recording a new decision.

## When to add an ADR

Only for decisions that are hard to reverse, surprising without context, and chosen after real trade-offs. Document **why** and **alternatives rejected** — not a restatement of the code. Routine requirements belong in requirements/design docs—not here.

## Agent docs

- [engineering-principles.md](../agents/engineering-principles.md)
- [security.md](../agents/security.md)
