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
| [0008](./0008-ai-guardrails-production-readiness.md) | AI guardrails and production readiness | Accepted |
| [0009](./0009-layered-tech-stack-policy.md) | Layered tech stack policy (Must vs Choose) | Accepted |

## Git tracking

**Yes — commit ADRs.** Everything under `docs/adr/` is **git-tracked** public documentation (not `.cursor/` and not `docs/local/`). Portfolio reviewers and hiring interviewers clone the repo; ADRs must be visible without Cursor rules.

- **Do commit:** `docs/adr/*.md`, index updates in this README
- **Do not commit:** `.cursor/rules/`, agent session notes, `.env`, credentials

## Format (English-only)

ADRs follow [0000-template.md](./0000-template.md). Unlike other public docs in [doc-conventions.md](../doc-conventions.md), ADRs are **English-only** — no `---` Japanese mirror. Operational detail and bilingual agent guidance live under `docs/agents/` and `CONTEXT.md`.

Required sections (in order):

1. **Context** — problem or constraint
2. **Decision** — what we chose (plain language)
3. **Consequences** — what becomes easier / harder
4. **Alternatives considered** — rejected options and why

Optional: **Related** links to design, architecture, or agent docs.

**Automated check:** `bash scripts/validate-adrs.sh` (runs in `ci-check.sh` and CI).

## Where detail lives (avoid duplication)

| Layer | Path | Purpose |
|-------|------|---------|
| ADR | `docs/adr/NNNN-*.md` | Irreversible **decision** + **why** + rejected alternatives |
| Agent handbook | `docs/agents/*.md` | How agents implement the decision (checklists, examples) |
| Short canonical | `CONTEXT.md` | Ubiquitous language + one-paragraph summaries with ADR links |
| Spec | `docs/design.md`, `docs/requirements.md` | Current **what / how**; link to ADR for rationale |

Do not copy ADR paragraphs into `design.md` or `CONTEXT.md` — link instead.

## When to add an ADR

Only when **all three** are true:

1. Hard to reverse later
2. Surprising without context
3. Result of a real trade-off (alternatives existed)

Routine requirements belong in `requirements.md` / `design.md` — not here. Policy bundles (0006–0008) are allowed when the decision is “adopt this bar for the public repo and agents,” with detail deferred to `docs/agents/`.

## Adding a new ADR

1. Copy `0000-template.md` → `docs/adr/NNNN-short-title.md` (next sequential ID).
2. Fill all four required sections; keep the file concise.
3. Add a row to the index table in this README.
4. Link from `docs/design.md` (or relevant spec) if the decision affects MVP behavior.
5. Run `bash scripts/validate-adrs.sh`.

Use branch prefix `docs/adr-...` when the PR is ADR-only.

## Agent docs

- [engineering-principles.md](../agents/engineering-principles.md) — expands ADR 0007
- [tech-stack.md](../agents/tech-stack.md) — expands ADR 0009
- [ai-production-readiness.md](../agents/ai-production-readiness.md) — expands ADR 0008
- [security.md](../agents/security.md) — expands ADR 0006
- [domain.md](../agents/domain.md) — consumer rules and spec precedence
