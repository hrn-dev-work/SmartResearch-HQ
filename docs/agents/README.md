# Agent documentation index

Read in this order before non-trivial implementation:

1. **`CONTEXT.md`** (repo root) — domain language, security, engineering principles, traps
2. **`docs/adr/`** — irreversible decisions (Why + alternatives)
3. **Project specs** — `docs/requirements.md`, `docs/design.md`, `README.md`
4. **Git / PR playbook** — [agent-git-playbook.md](../agent-git-playbook.md)

## This repository

| Doc | Purpose |
|-----|---------|
| [Domain consumer rules](./domain.md) | How to read and update `CONTEXT.md` / ADRs |
| [Security guardrails](./security.md) | OWASP / IPA, secrets, static analysis |
| [Engineering principles](./engineering-principles.md) | YAGNI, fail-fast, testability, Why-not-What |
| [Tech stack policy](./tech-stack.md) | Org Must/Choose profiles; SmartResearch-HQ = Profile B |
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

# エージェント向けドキュメント索引

非自明な実装の前に、次の順で読む:

1. **`CONTEXT.md`**（リポジトリルート）— ドメイン用語、セキュリティ、工学原則、落とし穴
2. **`docs/adr/`** — 不可逆な決定（Why + 却下案）
3. **プロジェクト仕様** — `docs/requirements.md`、`docs/design.md`、`README.md`
4. **Git / PR 手順** — [agent-git-playbook.md](../agent-git-playbook.md)

## 本リポジトリ

| ドキュメント | 目的 |
|--------------|------|
| [Domain consumer rules](./domain.md) | `CONTEXT.md` / ADR の読み方・更新ルール |
| [Security guardrails](./security.md) | OWASP / IPA、秘密情報、静的解析 |
| [Engineering principles](./engineering-principles.md) | YAGNI、フェイルファスト、テスト容易性、Why-not-What |
| [Tech stack policy](./tech-stack.md) | 組織 Must/Choose プロファイル；本リポ = プロファイル B |
| [Security rollout tasks](./security-rollout-tasks.md) | 組織/リポのセキュリティ強化バックログ |
| [ADR index](../adr/README.md) | アーキテクチャ決定記録 |

## Git & PR

| ドキュメント | 目的 |
|--------------|------|
| [Git & PR playbook](../agent-git-playbook.md) | ブランチ運用、フック、ship スクリプト |
| [Git hooks](../git-hooks.md) | pre-commit / post-push |
| [Doc conventions](../doc-conventions.md) | 公開 md: 英語 → `---` → 日本語 |

## 公開 vs ローカルエージェントファイル

一部リポは `AGENTS.md` と `.cursor/` を gitignore する。**コミットされる**エージェント入口は `CONTEXT.md` と本ディレクトリ。

Bootstrap ソース: `bootstrap-project-foundation.sh` 経由の `~/.cursor/templates/project-foundation/`。
