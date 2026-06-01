# ADR 0008: AI guardrails and production readiness

- **Status**: Accepted
- **Date**: 2026-05-31

## Context

SmartResearch-HQ is developed with heavy AI assistance. Without explicit guardrails, agents tend to:

- Add unverified PyPI/npm packages or deprecated APIs (hallucinated dependencies).
- Grow monolithic modules that mix HTTP, domain logic, and I/O, increasing defect rate and review cost.
- Implement mutating endpoints and workers that **double-apply** side effects on retry (network, queue redelivery).
- Rely on stdout or generic exceptions, making production incidents hard to diagnose.

Existing ADR 0006 covers **security standards**; ADR 0007 covers **YAGNI, fail-fast, testability, and Why-not-What**. Neither fully addresses **AI-specific workflow constraints** or **operational readiness** (idempotency, structured observability).

Portfolio mode still benefits: mock services should not corrupt state on double-submit; reviewers evaluate whether the author understands production trade-offs.

## Decision

Adopt four **AI Guardrails & Production Readiness** principles, summarized in [CONTEXT.md § System Architecture & Constraints](../../CONTEXT.md) and expanded in [docs/agents/ai-production-readiness.md](../agents/ai-production-readiness.md):

1. **Strict dependency control** — No new external package or deprecated API adoption without **explicit human approval** documented in the PR or issue. Agents must propose name, version, purpose, and alternatives; never invent package names.

2. **Context management & SRP** — Enforce single responsibility per module. When a file approaches **~300 lines** or mixes layers (route + domain + infrastructure), **propose a split before** adding more logic.

3. **Idempotency** — All side-effecting API operations and async job steps must be safe under at-least-once delivery. Use idempotency keys, conditional updates, natural keys, or deduplication tables as appropriate. Illegal state transitions must fail fast (aligns with ADR 0007).

4. **Observability** — Use structured logging (key fields: `job_id`, `status`, `mode`, exception type). Include enough context to debug without secrets. Important transitions and errors must not rely on bare print or silent catch-all handlers.

Implementation backlog: [ai-production-rollout-tasks.md](../agents/ai-production-rollout-tasks.md). Code changes may land in follow-up PRs.

## Alternatives considered

- **Fold into ADR 0007 only:** Rejected — 0007 targets portfolio *code quality*; dependency approval and idempotency are *process + ops* concerns that deserve separate indexing.
- **Cursor user rules only:** Rejected — not visible in public clone or to hiring reviewers.
- **Mandate OpenTelemetry + new logging library immediately:** Rejected — violates dependency control; start with stdlib logging + structured fields; revisit after human approval.
- **Hard CI fail at 300 lines:** Rejected — too noisy for legacy files; prefer WARN + tracked refactor tasks (A2.x in rollout tasks).

## Consequences

- Agents refuse to `pip install` / `npm install` new packages until the user approves.
- PRs touching POST/PUT/DELETE or worker tasks should mention idempotency strategy in Summary.
- Refactors for oversized files may be proposed without feature scope creep (YAGNI still applies to *abstractions*, not to *splitting tangled code*).
- Security guardrails (0006) still prohibit logging secrets; observability must redact tokens and PII.

## Related

- [0006](./0006-security-guardrails-public-standards.md) — OWASP / IPA / static analysis
- [0007](./0007-engineering-principles-for-agents.md) — YAGNI, fail-fast, testability, Why
- [CONTEXT.md](../../CONTEXT.md) — canonical short form

---

# ADR 0008: AI ガードレールと本番運用準備

- **Status**: Accepted
- **Date**: 2026-05-31

## Context

SmartResearch-HQ は AI 支援で開発される。明示的なガードレールがないと、エージェントは未検証パッケージの追加、関心の混合、リトライでの副作用二重適用、stdout 依存などを起こしやすい。ADR 0006 はセキュリティ、0007 は YAGNI・fail-fast・テスト容易性を扱うが、AI ワークフロー制約と運用準備（冪等性・可観測性）を完全にはカバーしない。

## Decision

四原則を採用する（要約は CONTEXT.md、詳細は docs/agents/ai-production-readiness.md）。

1. **厳格な依存関係管理** — 新規外部パッケージ・非推奨 API は人間の明示承認なしに採用しない。
2. **コンテキスト管理と SRP** — 約 300 行や層混在時は追記前に分割を提案する。
3. **冪等性** — 副作用 API とジョブは at-least-once で安全。不正遷移は fail-fast。
4. **可観測性** — 構造化ログ（job_id、status、mode 等）。秘密をログしない。

バックログ: ai-production-rollout-tasks.md。

## Alternatives considered

0007 への統合のみ、Cursor ルールのみ、新ログ lib 即必須、300 行 CI ハード fail はいずれも却下（理由は英語版と同様）。

## Consequences

承認なし install 禁止、変更系 PR は冪等性記載、巨大ファイル分割提案可、0006 の秘密禁止は継続。

## Related

0006、0007、CONTEXT.md。
