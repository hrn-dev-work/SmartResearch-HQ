# AI guardrails and production readiness

Rules for AI-assisted changes and production-grade runtime behavior. These complement [engineering-principles.md](./engineering-principles.md) (YAGNI, fail-fast, testability) and [security.md](./security.md) (secrets, OWASP/IPA).

Related: [CONTEXT.md § System Architecture & Constraints](../../CONTEXT.md), ADR [0008](../adr/0008-ai-guardrails-production-readiness.md). Rollout backlog: [ai-production-rollout-tasks.md](./ai-production-rollout-tasks.md).

---

## 1. Strict dependency control

**Why:** Agents hallucinate package names, add overlapping libraries, or adopt deprecated APIs without checking maintenance status. Each new dependency is supply-chain and review surface.

**Rules:**

- Do **not** add PyPI, npm, or system packages without **explicit human approval** first.
- Propose: package name, version pin strategy, purpose, and at least one alternative (stdlib, existing dep, or defer).
- Never invent package names — verify on PyPI/npm before mentioning them in a PR.
- Do not swap to deprecated APIs (e.g. legacy FastAPI/Next.js patterns) without user consent and an ADR if the change is irreversible.
- Dependabot and audit fixes are allowed; net-new capabilities are not.

**Backend examples (this repo):**

- Matching providers share existing HTTP clients — do not add a second HTTP library for one call site.
- Structured logging should start with stdlib `logging` + key=value fields until a JSON library is approved.

---

## 2. Context management and SRP

**Why:** Large files increase AI edit errors, hide test boundaries, and mix concerns (HTTP + domain + Playwright). Splitting early preserves reviewability.

**Rules:**

- One module, one reason to change (SRP).
- When a file approaches **~300 lines** or mixes route handlers + business rules + I/O, **propose a split before** adding logic.
- Prefer vertical slices (e.g. `matching/`, `export/`) over generic `utils.py` grab bags.
- Aligns with ADR 0007 testability — extracted domain logic is easier to pytest.

**Backend examples:**

- Keep status transition rules out of FastAPI route functions — use service modules (`MockResearchService`, production services).
- Playwright scrape scripts should not embed matching or export logic.

---

## 3. Idempotency

**Why:** Production uses queues (ARQ/Celery) and clients retry on timeouts. At-least-once delivery without idempotent handlers causes duplicate jobs, double exports, or inconsistent review state.

**Rules:**

- Mutating APIs (POST/PUT/PATCH/DELETE) and worker steps must be safe when executed **more than once**.
- Prefer: idempotency keys, conditional DB updates (`WHERE status = …`), natural keys (shop URL + window), or dedup tables.
- Illegal transitions must **fail fast** — do not no-op silently into wrong state (see engineering principles §2).
- Portfolio mock paths should behave correctly on double-submit in tests and demos.

**Backend examples:**

- Research job creation: document whether duplicate shop URL requests create a new job or return the existing one.
- Review select/reject: retry with the same payload must not double-apply or flip an already-finalized item.
- Export worker: redelivery must not append duplicate rows to Sheets (production); portfolio stays log-only (ADR 0005).

---

## 4. Observability

**Why:** `/diagnose` and log grep are the first tools in production incidents. Bare `print` and empty `except` hide root cause and waste on-call time.

**Rules:**

- Use **structured logs** — include `job_id`, `status`, `APP_MODE`, exception type, and correlation/request id when available.
- Log **state transitions** for research jobs (scrape → match → review → export).
- Do not log secrets, tokens, or full credential-bearing payloads (see security.md).
- API errors: stable client-facing `code` + message; stack traces **server-side only**.
- Replace bare `print` and silent catch-all handlers in hot paths when touching related code.

**Backend examples:**

- Worker failure: log `job_id`, previous status, target status, and exception class — not full HTML scrape dumps.
- FastAPI handlers: let domain exceptions map to 4xx; log 5xx with context before returning generic message.

---

## Checklist before opening a PR

- [ ] No new dependencies without documented human approval (strict dependency control)
- [ ] No file growing past ~300 lines without a split proposal (SRP)
- [ ] Mutating endpoints/workers describe idempotency strategy in PR Summary
- [ ] Errors and transitions log enough context without secrets (observability)
- [ ] [engineering-principles.md](./engineering-principles.md) checklist still satisfied
- [ ] `bash scripts/ci-check.sh` green

---

# AI ガードレールと本番運用準備

AI 支援変更と本番相当のランタイム向けルール。engineering-principles.md と security.md を補完する。関連: CONTEXT.md、ADR 0008、ai-production-rollout-tasks.md。

## 1. 厳格な依存関係管理

**Why:** 幻覚パッケージ・重複 lib・非推奨 API の無承認採用を防ぐ。

**Rules:** 人間承認なしに PyPI/npm を追加しない。名前・版・目的・代替を提示。Dependabot/監査修正のみ自動可。

## 2. コンテキスト管理と SRP

**Why:** 大ファイルは AI 編集ミスとテスト境界埋没を招く。

**Rules:** 約 300 行または handler+ドメイン+I/O 混在時は分割提案。縦スライスを優先。

## 3. 冪等性

**Why:** キュー再配信とクライアント再試行で二重副作用を防ぐ。

**Rules:** POST/PUT/PATCH/DELETE とワーカーは複数回実行でも安全。冪等キー・条件付き更新・自然キー。不正遷移は fail-fast。

## 4. 可観測性

**Why:** インシデントはログと diagnose から始める。

**Rules:** job_id・status・APP_MODE 等の構造化ログ。状態遷移を記録。秘密は出さない。API は安定 code + message。

## Checklist before opening a PR

- [ ] 承認なし新依存なし
- [ ] 300 行超えは分割提案
- [ ] 変更系は PR Summary に冪等性
- [ ] ログは十分・秘密なし
- [ ] engineering-principles チェックリスト
- [ ] ci-check.sh green
