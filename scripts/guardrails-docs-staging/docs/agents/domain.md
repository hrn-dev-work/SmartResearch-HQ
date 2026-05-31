# Domain documentation — consumer rules

## CONTEXT.md

- **Purpose:** Ubiquitous language, security guardrails, engineering principles, `_Avoid_` traps.
- **Not for:** Implementation details, file-by-file specs, ticket backlogs.
- **Update when:** Grilling resolves a new term or kills an ambiguous synonym.
- **Location:** Repository root `CONTEXT.md`.

## ADRs (`docs/adr/`)

Write an ADR only when **all three** are true:

1. Hard to reverse later
2. Surprising without context
3. Result of a real trade-off (alternatives existed)

Format: Context → Decision → Consequences → **Alternatives considered** (why other options were rejected).

Number files: `0001-short-title.md`. Index in `docs/adr/README.md`.

**Portfolio reviewers** read ADRs for *why* — not a prose duplicate of the code. See [engineering-principles.md](./engineering-principles.md) §4.

## Spec precedence

1. Accepted ADRs
2. Design / visual decisions (`docs/design.md`)
3. Requirements / acceptance criteria
4. Architecture
5. API / schema reference

When specs conflict, update the lower-priority doc— do not duplicate paragraphs across files.
