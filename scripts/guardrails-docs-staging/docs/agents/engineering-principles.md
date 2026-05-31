# Engineering principles for agents

These rules exist so **portfolio reviewers** (recruiters, hiring managers, code reviewers) can evaluate *design judgment*, not just feature completion. They apply to backend and frontend changes unless the user explicitly says otherwise.

Related: [CONTEXT.md § Engineering Principles](../../CONTEXT.md), ADR [0007](../adr/0007-engineering-principles-for-agents.md).

---

## 1. YAGNI and AHA (Avoid Hasty Abstractions)

**Why:** AI tends to add interfaces, factories, and “future-proof” layers before a second use case exists. Premature DRY creates tight abstractions that are harder to change than duplicated code.

**Rules:**

- Implement only what the **current** requirement needs (KISS).
- Do **not** introduce abstractions “for later” — no unused protocol classes, no generic plugin registries with one implementation.
- **Rule of Three:** extract shared code only after the same pattern appears **three or more** times with stable semantics.
- Prefer deleting speculative code over maintaining it.

**Backend examples (this repo):**

- `MatchingProvider` protocol exists because PA-API, Gemini, and manual paths are real — not hypothetical.
- Do not add a generic “Repository” layer until multiple aggregates share identical persistence patterns.

---

## 2. Fail-fast and guard clauses

**Why:** Deferred errors in async pipelines (scrape → match → review) make `/diagnose` expensive. Early failure preserves context and keeps handlers flat.

**Rules:**

- Validate inputs at the HTTP/CLI boundary; return 4xx with clear messages.
- Use **guard clauses** — reject invalid state first, then happy path with minimal nesting.
- Do not swallow exceptions to “keep going” unless an ADR documents retry/DLQ behavior (production workers only).
- Raise domain exceptions (`app.core.exceptions`) instead of returning ambiguous `None`.

**Backend examples:**

- Reject malformed shop URLs before enqueueing scrape work.
- `APP_MODE` mismatch between frontend and API should fail loudly in E2E, not render empty UI.

---

## 3. Design for testability

**Why:** `bash scripts/ci-check.sh` runs pytest on every PR. Untestable code becomes regression debt immediately.

**Rules:**

- Keep **business logic** (matching rules, status transitions, export filtering) in functions/classes that do not import Playwright, Redis, or live HTTP clients.
- Use **dependency injection** at composition roots (`deps.py`, service factories) so tests pass fakes without heavy mocking.
- Prefer **pure functions** where possible — same inputs → same outputs, no hidden globals.
- New behavior should include pytest coverage when logic is non-trivial; do not add tests that only assert mocks were called.

**Backend examples:**

- `MockResearchService` vs production services share API contracts — tests lock behavior without browsers.
- Matcher selection via `MATCHING_PROVIDER` env keeps tests on `amazon_search` / `manual` without Gemini keys.

---

## 4. Document Why, not What

**Why:** Reviewers reading `APP_MODE=portfolio` already see *what* the code does. They need *why* dual-mode, log-only export, and human review exist — that demonstrates engineering maturity.

**Rules:**

- **ADRs:** Context → Decision → Consequences → **Alternatives considered** (why others were rejected).
- **Comments:** Only for non-obvious trade-offs, invariants, or external constraints — not narrating each line.
- **PR / commit bodies:** Explain motivation and risk, not a file list (file list is git's job).
- Do not duplicate ADR rationale in CONTEXT.md — link instead.

**Portfolio signal:** A reviewer should answer “why mock export?” from ADR 0005 in under two minutes.

---

## Checklist before opening a PR

- [ ] No speculative abstractions (YAGNI / Rule of Three)
- [ ] Invalid inputs fail at boundaries (fail-fast)
- [ ] Logic testable without live infra where feasible
- [ ] New irreversible choices have an ADR with **Why** and rejected alternatives
- [ ] `bash scripts/ci-check.sh` green
