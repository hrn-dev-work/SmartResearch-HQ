# Domain documentation — consumer rules

## CONTEXT.md

- **Purpose:** Ubiquitous language only. One or two sentences per term + `_Avoid_` list.
- **Not for:** Implementation details, file-by-file specs, ticket backlogs.
- **Update when:** Grilling resolves a new term or kills an ambiguous synonym.
- **Location:** Repository root `CONTEXT.md`.

## ADRs (`docs/adr/`)

Write an ADR only when **all three** are true:

1. Hard to reverse later
2. Surprising without context
3. Result of a real trade-off (alternatives existed)

Format: Context → Decision → Consequences → (optional) Alternatives considered.

Number files: `0001-short-title.md`. Index in `docs/adr/README.md`.

## Spec precedence

Define per project. Default suggestion:

1. Design / visual decisions
2. Requirements / acceptance criteria
3. Architecture
4. API / schema reference

When specs conflict, update the lower-priority doc— do not duplicate paragraphs across files.
