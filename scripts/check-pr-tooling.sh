#!/usr/bin/env bash
# Self-check PR / docs tooling (no GitHub network). Fails fast before push/PR.
# Usage: bash scripts/check-pr-tooling.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

required=(
  scripts/validate-public-docs.sh
  scripts/check-staged-branch-scope.sh
  scripts/check-staged-docs-crosslinks.sh
  scripts/validate-pr-body.sh
  scripts/render-pr-body.sh
  scripts/sync-pr-body.sh
  scripts/update-pr-body-from-file.sh
  scripts/gh-pr-branch.sh
  scripts/pr-ci-checkbox.sh
  scripts/pr-deploy-demo-checkbox.sh
)

echo "== pr tooling: required scripts =="
for f in "${required[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "MISSING (do not delete / gitignore): $f" >&2
    exit 1
  fi
  chmod +x "$f" 2>/dev/null || true
done

echo "== pr tooling: forbidden gh api body=@ (runtime only) =="
bad="$(grep -R --include='*.sh' -nE '[[:space:]]-f[[:space:]]+"?body=@' scripts/ 2>/dev/null \
  | grep -vE 'check-pr-tooling\.sh:|validate-pr-body\.sh:' \
  | grep -vE ':[0-9]+:[[:space:]]*#' || true)"
if [[ -n "$bad" ]]; then
  echo "ERROR: use gh_api_patch_pr_body (python3 JSON), not -f body=@file:" >&2
  echo "$bad" >&2
  exit 1
fi

echo "== pr tooling: no ci-check cycle via pr-ci-checkbox =="
# Match runtime invokes only (comments may mention ci-check.sh for documentation).
if grep -vE '^\s*#' "$ROOT/scripts/pr-ci-checkbox.sh" | grep -qE 'ci-check\.sh'; then
  echo "ERROR: pr-ci-checkbox.sh must not invoke ci-check.sh (infinite loop with check-pr-tooling)" >&2
  exit 1
fi

echo "== pr tooling: public docs bilingual =="
bash scripts/validate-public-docs.sh README.md

echo "== pr tooling: PR body manual template =="
manual_body="$(RENDER_PR_BODY_SKIP_CI_CHECKBOX=1 bash scripts/render-pr-body.sh manual feat/self-check-test)"
bash scripts/validate-pr-body.sh --stdin <<<"$manual_body"

echo "== pr tooling: PR body auto template =="
auto_body="$(RENDER_PR_BODY_SKIP_CI_CHECKBOX=1 bash scripts/render-pr-body.sh auto docs/frontend-structure-viz main)"
bash scripts/validate-pr-body.sh --stdin <<<"$auto_body"

echo "PR tooling self-check passed."
