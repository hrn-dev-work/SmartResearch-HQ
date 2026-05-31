# Security rollout tasks

Backlog for repo and org settings beyond ADR 0006 documentation.

---

## P0 — CI / repo (this clone)

| ID | Task | Status |
|----|------|--------|
| S0.1 | ADR 0006 + CONTEXT security sections merged | done |
| S0.2 | `secret-audit` job green on `main` | done (CI) |
| S0.3 | CodeQL workflow enabled | done (CI) |
| S0.4 | `.env.example` has no real values | verify on change |

---

## P1 — GitHub org / repo settings

| ID | Task | Notes |
|----|------|-------|
| S1.1 | Enable **Dependabot** alerts + security updates | All SmartResearch-HQ deps |
| S1.2 | Enable **Secret scanning** + push protection | Org settings |
| S1.3 | Branch protection: require `backend`, `frontend`, `secret-audit` | PR merge path |

---

## P2 — Cross-repo bootstrap

| ID | Task | Notes |
|----|------|-------|
| S2.1 | Copy `docs/agents/security.md` template to sibling repos | Via `bootstrap-project-foundation.sh` |
| S2.2 | Add `secret-audit` CI to sibling repos | Match SmartResearch-HQ pattern |

---

## P3 — Production hardening (post-MVP)

| ID | Task | Notes |
|----|------|-------|
| S3.1 | Auth provider + session ADR before multi-user | Reopens ADR 0002 |
| S3.2 | Rate limiting on public API (WBS 4.4) | FastAPI middleware |
| S3.3 | CSP / security headers on Vercel | When auth ships |

---

## Verification

```bash
bash scripts/secret-audit.sh
bash scripts/ci-check.sh
```
