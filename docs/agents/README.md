# Agent documentation index

Read in this order before non-trivial implementation:

1. **`CONTEXT.md`** (repo root) — domain language, traps, constraints
2. **`docs/adr/`** — irreversible decisions (if any ADRs exist)
3. **Project specs** — e.g. `docs/requirements.md`, `docs/design.md`, `README.md`
4. **Git / PR playbook** — project-specific link below (if present)

## This repository

| Doc | Purpose |
|-----|---------|
| [Domain consumer rules](./domain.md) | How to read and update `CONTEXT.md` / ADRs |
| [ADR index](../adr/README.md) | Architecture decision records |

## Git & PR (link only — do not duplicate)

Add a row when your project has a playbook:

| Doc | Purpose |
|-----|---------|
| [Git & PR playbook](../agent-git-playbook.md) | Branch workflow, hooks, ship scripts |

## Public vs local agent files

Some repos gitignore `AGENTS.md` and `.cursor/`. **Committed** agent entry points are `CONTEXT.md` and this directory.

Bootstrap source: `~/.cursor/templates/project-foundation/` via `bootstrap-project-foundation.sh`.
