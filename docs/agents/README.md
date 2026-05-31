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
