# ADR 0006: Security guardrails and public standards

- **Status**: Accepted
- **Date**: 2026-05-31

## Context

Agents and contributors need explicit security expectations beyond ad-hoc review. The portfolio is public; production will handle real credentials and scraped data. We must align with widely cited standards so hiring reviewers and CI tooling share the same bar.

## Decision

1. Document **Security Guardrails** in `CONTEXT.md` and [docs/agents/security.md](../agents/security.md).
2. Treat **OWASP Top 10 (latest)** and **IPA secure web development guidelines** as mandatory design references for new code (official link and Japanese title in [security.md](../agents/security.md)).
3. Treat security-related **linter / CodeQL / secret-audit** findings and TypeScript **`any` / unsafe casts** as merge blockers unless waived in a follow-up ADR with explicit scope.
4. Track org-level enablement (Dependabot, secret scanning, rate limits) in [security-rollout-tasks.md](../agents/security-rollout-tasks.md).
5. Keep CI workflow guardrails in [security-scanning.md](../security-scanning.md) (complementary, not duplicate).

## Alternatives considered

- **Security only in `.cursor/rules`:** Rejected — `.cursor/` is gitignored; public clone and reviewers would not see it.
- **Single paragraph in README:** Rejected — too shallow for OWASP/IPA mapping and agent grilling.
- **Defer until production auth:** Rejected — injection and secret-handling risks exist in portfolio mode too.

## Consequences

- Agents run security grilling (Round 1 extension) for API/auth/input work.
- Waivers require documentation, not silent suppression in CI.
- Rollout tasks may span multiple PRs; ADR stays Accepted while backlog items complete.

See [CONTEXT.md §5](../../CONTEXT.md) and [design.md §11](../design.md) where security touches deployment env vars.
