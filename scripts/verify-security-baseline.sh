#!/usr/bin/env bash
# Verify Level A security baseline end-to-end.
# Usage: bash scripts/verify-security-baseline.sh [--require-codeql]
# Exit 0 = PASS. Exit 1 = FAIL.
# ALLOW_PARTIAL=1 exits 0 after OPEN RISK (user waiver only; never silent CI green).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

REQUIRE_CODEQL=0
[[ "${1:-}" == "--require-codeql" ]] && REQUIRE_CODEQL=1

fail=0
open=()
ok() { echo "OK: $*"; }
bad() { echo "FAIL: $*" >&2; fail=1; }
risk() { echo "OPEN RISK: $*" >&2; open+=("$*"); fail=1; }

echo "== verify security baseline =="

[[ -f .github/dependabot.yml ]] && ok "dependabot.yml" || bad "missing .github/dependabot.yml"

# Require job key and/or job name secret-audit (check context), not free-text alone.
has_secret_audit_job=0
if [[ -d .github/workflows ]]; then
  while IFS= read -r -d '' wf; do
    if grep -Eq '^[[:space:]]*secret-audit:[[:space:]]*$' "$wf" 2>/dev/null \
      || grep -Eq '^[[:space:]]*name:[[:space:]]*["'\'']?secret-audit["'\'']?[[:space:]]*$' "$wf" 2>/dev/null; then
      has_secret_audit_job=1
      break
    fi
  done < <(find .github/workflows -type f \( -name '*.yml' -o -name '*.yaml' \) -print0 2>/dev/null)
fi
if [[ "$has_secret_audit_job" -eq 1 ]]; then
  ok "workflow defines job secret-audit (name or key)"
else
  bad "no job key/name secret-audit under .github/workflows (required check context)"
fi

[[ -f scripts/secret-audit.sh ]] && ok "scripts/secret-audit.sh" || bad "missing scripts/secret-audit.sh"
[[ -f scripts/enable-github-secret-scanning.sh ]] && ok "enable-github-secret-scanning.sh" || risk "missing enable-github-secret-scanning.sh"
[[ -f scripts/apply-branch-protection.sh ]] && ok "apply-branch-protection.sh" || risk "missing apply-branch-protection.sh"
[[ -f .trivyignore ]] && ok ".trivyignore" || bad "missing .trivyignore"

if [[ -f docs/agents/security.md ]]; then
  ok "docs/agents/security.md"
else
  risk "docs/agents/security.md missing"
fi

if [[ -f scripts/pre-commit-secret-check.sh ]]; then
  ok "pre-commit-secret-check.sh present"
  if [[ -x .git/hooks/pre-commit ]] || [[ -f .githooks/pre-commit ]] || [[ -f .husky/pre-commit ]]; then
    ok "some pre-commit hook path exists"
  else
    risk "pre-commit secret script not wired to a hook (document install)"
  fi
else
  risk "pre-commit-secret-check.sh missing"
fi

if [[ -f scripts/secret-audit.sh ]]; then
  if bash scripts/secret-audit.sh --strict; then
    ok "secret-audit.sh --strict"
  else
    bad "secret-audit.sh --strict failed"
  fi
fi

if ! command -v gh >/dev/null 2>&1 || ! gh auth status >/dev/null 2>&1; then
  risk "gh unavailable/unauthenticated — cannot verify platform controls"
else
  REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)"
  if [[ -z "${REPO:-}" ]]; then
    risk "no GitHub remote"
  else
    ss="$(gh api "repos/$REPO" --jq '.security_and_analysis.secret_scanning.status // "unknown"' 2>/dev/null || echo unknown)"
    pp="$(gh api "repos/$REPO" --jq '.security_and_analysis.secret_scanning_push_protection.status // "unknown"' 2>/dev/null || echo unknown)"
    if [[ "$ss" == "enabled" && "$pp" == "enabled" ]]; then
      ok "Secret Scanning + Push Protection enabled"
    else
      risk "Secret Scanning/Push Protection not enabled (ss=$ss pp=$pp) https://github.com/$REPO/settings/security_analysis"
    fi

    BR="$(gh api "repos/$REPO" --jq .default_branch)"
    if prot="$(gh api "repos/$REPO/branches/$BR/protection" 2>/dev/null)"; then
      if ! command -v jq >/dev/null 2>&1; then
        risk "jq missing — cannot verify required context secret-audit on $BR"
      elif echo "$prot" | jq -e '.required_status_checks.contexts | index("secret-audit")' >/dev/null 2>&1; then
        ok "branch protection requires secret-audit on $BR"
      else
        risk "branch protection on $BR without required context secret-audit"
      fi
      if command -v jq >/dev/null 2>&1 && echo "$prot" | jq -e '.allow_force_pushes.enabled == true' >/dev/null 2>&1; then
        risk "force-push allowed on $BR"
      fi
    else
      risk "no branch protection on $BR — https://github.com/$REPO/settings/branches"
    fi
  fi
fi

if [[ "$REQUIRE_CODEQL" -eq 1 ]]; then
  codeql_ok=0
  if [[ -d .github/workflows ]]; then
    while IFS= read -r -d '' wf; do
      if grep -Eq 'codeql-action' "$wf" 2>/dev/null; then
        codeql_ok=1
        break
      fi
    done < <(find .github/workflows -type f \( -name '*.yml' -o -name '*.yaml' \) -print0 2>/dev/null)
  fi
  if [[ "$codeql_ok" -eq 1 ]]; then
    ok "CodeQL workflow present"
  else
    bad "CodeQL required but workflow missing"
  fi
fi

echo "== verify done =="
if [[ "$fail" -ne 0 ]]; then
  if [[ ${#open[@]} -gt 0 ]]; then
    echo "Open risks:" >&2
    printf '  - %s\n' "${open[@]}" >&2
  fi
  if [[ "${ALLOW_PARTIAL:-0}" == "1" ]]; then
    echo "Result: PARTIAL (ALLOW_PARTIAL=1 — user waiver only, not CI greenwash)" >&2
    exit 0
  fi
  echo "Result: FAIL" >&2
  exit 1
fi
echo "Result: PASS"
exit 0
