# Agent documentation index

Read in this order before non-trivial implementation:

1. **`CONTEXT.md`** (repo root) — domain language, security, engineering principles, AI guardrails, traps
2. **`docs/adr/`** — irreversible decisions (Why + alternatives)
3. **Project specs** — `docs/requirements.md`, `docs/design.md`, `README.md`
4. **Git / PR playbook** — [agent-git-playbook.md](../agent-git-playbook.md)

## This repository

| Doc | Purpose |
|-----|---------|
| [Domain consumer rules](./domain.md) | How to read and update `CONTEXT.md` / ADRs |
| [Security guardrails](./security.md) | OWASP / IPA, secrets, static analysis |
| [Engineering principles](./engineering-principles.md) | YAGNI, fail-fast, testability, Why-not-What |
| [AI guardrails & production readiness](./ai-production-readiness.md) | Dependency control, SRP, idempotency, observability |
| [Security rollout tasks](./security-rollout-tasks.md) | Org/repo hardening backlog |
| [ADR index](../adr/README.md) | Architecture decision records |

## Git & PR

| Doc | Purpose |
|-----|---------|
| [Git & PR playbook](../agent-git-playbook.md) | Branch workflow, hooks, ship scripts |
| [Git hooks](../git-hooks.md) | pre-commit / post-push |
| [Doc conventions](../doc-conventions.md) | Public md: EN → `---` → JA |

## Public vs local agent files

Some repos gitignore `AGENTS.md` and `.cursor/`. **Committed** agent entry points are `CONTEXT.md` and this directory.

Bootstrap source: `~/.cursor/templates/project-foundation/` via `bootstrap-project-foundation.sh`.

---

# エージェント文書インデックス（日本語）

非自明な実装の前に、この順で読む:

1. **`CONTEXT.md`**（リポジトリルート）— ドメイン言語、セキュリティ、工学原則、AI ガードレール、トラップ
2. **`docs/adr/`** — 不可逆な決定（Why + 代替案）
3. **プロジェクト仕様** — `docs/requirements.md`, `docs/design.md`, `README.md`
4. **Git / PR プレイブック** — [agent-git-playbook.md](../agent-git-playbook.md)

## 本リポジトリ

| 文書 | 目的 |
|------|------|
| [Domain consumer rules](./domain.md) | `CONTEXT.md` / ADR の読み方・更新ルール |
| [Security guardrails](./security.md) | OWASP / IPA、秘密情報、静的解析 |
| [Engineering principles](./engineering-principles.md) | YAGNI、fail-fast、テスト容易性、Why-not-What |
| [AI guardrails & production readiness](./ai-production-readiness.md) | 依存管理、SRP、冪等性、可観測性 |
| [Security rollout tasks](./security-rollout-tasks.md) | 組織 / リポ強化バックログ |
| [ADR index](../adr/README.md) | アーキテクチャ決定記録 |

## Git と PR

| 文書 | 目的 |
|------|------|
| [Git & PR playbook](../agent-git-playbook.md) | ブランチ運用、フック、ship スクリプト |
| [Git hooks](../git-hooks.md) | pre-commit / post-push |
| [Doc conventions](../doc-conventions.md) | 公開 md: EN → `---` → JA |

## 公開 vs ローカルエージェントファイル

一部リポは `AGENTS.md` と `.cursor/` を gitignore する。**コミット済み**の入口は `CONTEXT.md` と本ディレクトリ。

Bootstrap 元: `bootstrap-project-foundation.sh` 経由の `~/.cursor/templates/project-foundation/`。
