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

## Template

Copy `0000-template.md` when recording a new decision.

## When to add an ADR

Only for decisions that are hard to reverse, surprising without context, and chosen after real trade-offs. Document **why** and **alternatives rejected** — not a restatement of the code. Routine requirements belong in requirements/design docs—not here.

## Agent docs

- [engineering-principles.md](../agents/engineering-principles.md)
- [ai-production-readiness.md](../agents/ai-production-readiness.md)
- [security.md](../agents/security.md)

---

# アーキテクチャ決定記録（日本語）

本リポジトリの Accepted 決定。ユーザーが明示的に再オープンを求めない限り、**Accepted ADR を再議論しない**。

| ID | タイトル | 状態 |
|----|----------|------|
| [0001](./0001-portfolio-first-dual-mode.md) | Portfolio-first dual mode | Accepted |
| [0002](./0002-no-authentication-mvp.md) | MVP に認証なし | Accepted |
| [0003](./0003-review-required-human-in-loop.md) | レビュー必須（human-in-the-loop） | Accepted |
| [0004](./0004-pluggable-candidate-matching.md) | プラガブル候補マッチング | Accepted |
| [0005](./0005-portfolio-sheets-export-log-only.md) | Portfolio Sheets エクスポートはログのみ | Accepted |
| [0006](./0006-security-guardrails-public-standards.md) | セキュリティガードレール（OWASP / IPA） | Accepted |
| [0007](./0007-engineering-principles-for-agents.md) | 工学原則（YAGNI、fail-fast、テスト、Why） | Accepted |
| [0008](./0008-ai-guardrails-production-readiness.md) | AI ガードレールと本番運用準備 | Accepted |

## テンプレート

新規決定時は `0000-template.md` をコピーする。

## ADR を追加するタイミング

後から戻しにくく、文脈なしでは驚き、実際のトレードオフの後にのみ。**why** と **却下した代替案** を書く — コードの言い換えではない。通常要件は requirements/design へ。

## エージェント文書

- [engineering-principles.md](../agents/engineering-principles.md)
- [ai-production-readiness.md](../agents/ai-production-readiness.md)
- [security.md](../agents/security.md)
