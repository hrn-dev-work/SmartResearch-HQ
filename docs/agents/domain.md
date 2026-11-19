# Domain documentation — consumer rules

## CONTEXT.md

- **Purpose:** Ubiquitous language, security guardrails, engineering principles, AI guardrails, `_Avoid_` traps.
- **Not for:** Implementation details, file-by-file specs, ticket backlogs.
- **Update when:** Grilling resolves a new term or kills an ambiguous synonym.
- **Location:** Repository root `CONTEXT.md`.
- **Bilingual:** English block → language-boundary `---` → `# SmartResearch-HQ（日本語）` mirror per [doc-conventions.md](../doc-conventions.md). **Agents read the English block only** (through the `---` immediately before the Japanese `#` heading).

## ADRs (`docs/adr/`)

Write an ADR only when **all three** are true:

1. Hard to reverse later
2. Surprising without context
3. Result of a real trade-off (alternatives existed)

Format: Context → Decision → Consequences → **Alternatives considered** (why other options were rejected).

Number files: `0001-short-title.md`. Index in `docs/adr/README.md`.

**Git:** Commit all `docs/adr/*.md` — they are public, tracked documentation (unlike `.cursor/`). Validated by `bash scripts/validate-adrs.sh`.

**Language:** English-only in ADRs. Bilingual mirrors belong in `docs/agents/` or top-level `docs/*.md` per [doc-conventions.md](../doc-conventions.md).

**Layering:** ADR = decision + why; `docs/agents/` = operational detail; `CONTEXT.md` = short summary + links. Do not duplicate ADR prose across files.

**Portfolio reviewers** read ADRs for *why* — not a prose duplicate of the code. See [engineering-principles.md](./engineering-principles.md) §4.

## Spec precedence

1. Accepted ADRs
2. Design / visual decisions (`docs/design.md`)
3. Requirements / acceptance criteria
4. Architecture
5. API / schema reference

When specs conflict, update the lower-priority doc— do not duplicate paragraphs across files.
