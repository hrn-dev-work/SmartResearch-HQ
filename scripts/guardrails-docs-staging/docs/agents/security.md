# Security guardrails

Read before adding API routes, env vars, forms, file I/O, auth, or third-party integrations.

Canonical summary: [CONTEXT.md § Security Guardrails](../../CONTEXT.md). ADR: [0006](../adr/0006-security-guardrails-public-standards.md). CI workflow rules: [security-scanning.md](../security-scanning.md).

---

## Secrets and configuration

- Never commit `.env`, API keys, tokens, `credentials.json`, or private keys.
- `.env.example`: **key names only** — empty or placeholder values.
- Server-only secrets on the backend. **`NEXT_PUBLIC_*` / browser env is public.**
- Do not log secrets, session tokens, or full credential-bearing request bodies.

---

## Input, output, and dependencies

| Area | Rule |
|------|------|
| HTTP input | Pydantic models + explicit validation; reject unknown enums early |
| SQL | ORM / parameterized queries only — no string-concatenated SQL |
| Shell / subprocess | No user-controlled command fragments |
| URLs / fetch | Allowlist hosts where possible; beware SSRF on scrape/match integrations |
| Error responses | No stack traces or internal paths to clients in production |
| Dependencies | Address Dependabot / audit findings on PRs — do not ignore without ADR |

---

## OWASP Top 10 (mapping for this codebase)

| Risk | Mitigation in SmartResearch-HQ |
|------|--------------------------------|
| Injection | Pydantic + SQLAlchemy; no raw SQL from user input |
| Broken auth | ADR 0002 — no auth in MVP; do not add partial auth without reopen |
| Sensitive data exposure | Secrets server-side; portfolio log-only export (ADR 0005) |
| Misconfiguration | `APP_MODE`, CORS (`ALLOWED_ORIGINS`), env in deployment guide |
| XSS | React default escaping; no `dangerouslySetInnerHTML` without sanitization ADR |
| SSRF | Scrape targets validated; no open proxy endpoints |
| Vulnerable components | CI secret-audit + Dependabot (see rollout tasks) |

---

## IPA「安全なウェブサイトの作り方」

Apply at implementation level:

- **XSS:** encode output; validate input length and charset on API boundaries.
- **SQL injection:** ORM-only data access in production paths.
- **CSRF:** relevant when auth/cookies are added (post-MVP); document in ADR before shipping.
- **Session / access control:** deferred per ADR 0002 — do not half-implement.

---

## Static analysis and TypeScript type safety

- **Merge blockers:** secret-audit CI, CodeQL new alerts on changed code, ESLint security-related rules.
- **TypeScript:** avoid `any` and unsafe casts (`as unknown as T`) unless ADR-waived with justification.
- **Python:** Ruff + pytest in `ci-check.sh`; do not disable checks to greenwash CI.

---

## Grilling — security (Round 1 extension)

When scope touches API, auth, env, or user input, add:

4. **Security surface** — new secrets? new public endpoints? new user-controlled URLs or uploads?
5. **Compliance** — does this touch OWASP/IPA items above? static analysis clean?

---

## Related

- [security-rollout-tasks.md](./security-rollout-tasks.md) — org/repo settings backlog
- [docs/deployment-guide.md](../deployment-guide.md) — production env vars
- `scripts/secret-audit.sh`, `.github/workflows/ci.yml`
