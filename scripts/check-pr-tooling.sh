#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
required=(scripts/validate-public-docs.sh scripts/check-staged-branch-scope.sh scripts/check-staged-docs-crosslinks.sh scripts/validate-pr-body.sh scripts/render-pr-body.sh scripts/sync-pr-body.sh scripts/update-pr-body-from-file.sh scripts/gh-pr-branch.sh)
echo "== pr tooling: required scripts =="
for f in "${required[@]}"; do
  [[ -f "$f" ]] || { echo "MISSING: $f" >&2; exit 1; }
  chmod +x "$f" 2>/dev/null || true
done
echo "== pr tooling: forbidden gh api body=@ (runtime only) =="
if bad="$(grep -R --include='*.sh' -nE '[[:space:]]-f[[:space:]]+"?body=@' scripts/ 2>/dev/null || true)"; then
  echo "ERROR: use gh_api_patch_pr_body, not -f body=@file:" >&2
  echo "$bad" >&2
  exit 1
fi
echo "== pr tooling: public docs bilingual =="
bash scripts/validate-public-docs.sh README.md
echo "== pr tooling: PR body manual template =="
manual_body="$(bash scripts/render-pr-body.sh manual feat/self-check-test)"
bash scripts/validate-pr-body.sh --stdin <<<"$manual_body"
echo "== pr tooling: PR body auto template =="
auto_body="$(bash scripts/render-pr-body.sh auto docs/frontend-structure-viz main)"
bash scripts/validate-pr-body.sh --stdin <<<"$auto_body"
echo "PR tooling self-check passed."
