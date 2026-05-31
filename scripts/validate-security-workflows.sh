#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CODEQL="$ROOT/.github/workflows/codeql.yml"
CI="$ROOT/.github/workflows/ci.yml"

errors=0

fail() {
  echo "[FAIL] $1" >&2
  errors=$((errors + 1))
}

pass() {
  echo "[OK] $1"
}

if [[ ! -f "$CODEQL" ]]; then
  fail "Missing $CODEQL"
else
  if grep -nE "autobuild" "$CODEQL" >/dev/null; then
    fail "codeql.yml must not use autobuild"
  else
    pass "codeql.yml does not use autobuild"
  fi

  if grep -nE "source-root" "$CODEQL" >/dev/null; then
    fail "codeql.yml must not set source-root"
  else
    pass "codeql.yml does not set source-root"
  fi

  build_mode_none_count="$(grep -nE "build-mode: none" "$CODEQL" | wc -l | tr -d " ")"
  if [[ "${build_mode_none_count:-0}" -lt 2 ]]; then
    fail "codeql.yml must include build-mode: none for monorepo language matrix"
  else
    pass "codeql.yml includes build-mode: none"
  fi

  if grep -nE "build-mode:\s*(autobuild|manual)" "$CODEQL" >/dev/null; then
    fail "codeql.yml must not use build-mode autobuild/manual"
  else
    pass "codeql.yml build-mode values are guardrail-compliant"
  fi

  if ! grep -nE "npm run build" "$CODEQL" >/dev/null; then
    fail "codeql.yml must run npm build in JS/TS analysis path"
  else
    pass "codeql.yml includes npm build step"
  fi
fi

if [[ ! -f "$CI" ]]; then
  fail "Missing $CI"
else
  if ! grep -nE "gitleaks/gitleaks-action@[0-9a-f]{40}" "$CI" >/dev/null; then
    fail "ci.yml must pin gitleaks action by full SHA"
  else
    pass "ci.yml pins gitleaks action"
  fi

  if ! grep -nE "aquasecurity/trivy-action@[0-9a-f]{40}" "$CI" >/dev/null; then
    fail "ci.yml must pin trivy action by full SHA"
  else
    pass "ci.yml pins trivy action"
  fi
fi

if [[ "$errors" -gt 0 ]]; then
  echo "Security workflow guardrails: FAILED ($errors issue(s))" >&2
  exit 1
fi

echo "Security workflow guardrails: PASS"
