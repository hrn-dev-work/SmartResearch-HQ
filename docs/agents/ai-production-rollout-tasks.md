# AI guardrails and production readiness — rollout tasks

Backlog to implement ADR 0008 beyond CONTEXT and agent documentation.

---

## P0 — Policy on `main` (docs)

| ID | Task | Status |
|----|------|--------|
| A0.1 | CONTEXT § AI Guardrails & Production Readiness merged | done |
| A0.2 | ADR 0008 Accepted + `docs/agents/ai-production-readiness.md` | done |
| A0.3 | Agent index README links to new docs | done |

---

## P1 — Dependency control (process + CI)

| ID | Task | Notes |
|----|------|-------|
| A1.1 | Document **dependency proposal template** in agent-git-playbook (package name, version, why, alternatives) | Agent must paste before adding deps |
| A1.2 | Pre-commit or CI **WARN** when `requirements.txt` / `package.json` / `package-lock.json` change without `deps:` in commit subject or PR Summary | Non-blocking at first |
| A1.3 | Pin major deps in PR review checklist | Dependabot handles patches |

---

## P2 — SRP / file size (quality)

| ID | Task | Notes |
|----|------|-------|
| A2.1 | Audit backend files **>300 lines**; open refactor issues with split plan | `backend/app/` priority |
| A2.2 | Optional CI script: **WARN** on new files >300 lines or +150 line single-file diffs | `scripts/check-file-size-hints.sh` |
| A2.3 | Frontend: same threshold for `page.tsx` / large components | Align with i18n message extraction |

---

## P3 — Idempotency (production paths)

| ID | Task | Notes |
|----|------|-------|
| A3.1 | **Research job create**: document idempotency strategy (client `Idempotency-Key` or dedupe by shop URL + window) | API spec + ADR note if schema change |
| A3.2 | **Review select/reject**: ensure duplicate POST does not double-write or flip state incorrectly | pytest: retry same payload |
| A3.3 | **Export / Sheets push**: worker retry must not duplicate rows | production only; portfolio stays log-only |
| A3.4 | ARQ/Celery tasks: pass job id; make status transitions conditional (`WHERE status = …`) | Fail-fast on illegal transition |

---

## P4 — Observability

| ID | Task | Notes |
|----|------|-------|
| A4.1 | Standardize backend logger: module name, level, **JSON or key=value** fields (`job_id`, `status`, `mode`) | No new dep without A1 approval |
| A4.2 | Replace bare `print` / empty `except` in `backend/app/` hot paths | Pair with fail-fast |
| A4.3 | API error responses: stable `code` + message; log stack trace server-side only | OWASP misconfiguration |
| A4.4 | Document **correlation id** propagation (header `X-Request-ID` or middleware) | Post-MVP if not in MVP |

---

## P5 — Cross-cutting verification

| ID | Task | Notes |
|----|------|-------|
| A5.1 | Extend agent PR checklist (engineering-principles.md) with 4 AI/production items | done |
| A5.2 | Add grilling Round 1 extension: deps / idempotency / logs for API changes | Mirror security.md pattern |
| A5.3 | `bash scripts/ci-check.sh` green after each P3/P4 code change | Required |

---

## Verification

```bash
bash scripts/ci-check.sh
# After A4.1:
# grep -R "job_id" backend/app/ --include='*.py' | head
```

---

# AI ガードレールと本番運用準備 — ロールアウトタスク

ADR 0008 を CONTEXT/agent 文書の先を実装するバックログ。

## P0 — ポリシー（ドキュメント）

| ID | Task | Status |
|----|------|--------|
| A0.1 | CONTEXT § AI Guardrails マージ | done |
| A0.2 | ADR 0008 + ai-production-readiness.md | done |
| A0.3 | Agent README リンク | done |

## P1 — 依存関係管理

| ID | Task | Notes |
|----|------|-------|
| A1.1 | 依存提案テンプレを playbook に | 追加前に貼る |
| A1.2 | deps 変更時 WARN | 最初 non-blocking |
| A1.3 | major dep pin をレビュー | Dependabot |

## Verification

bash scripts/ci-check.sh
