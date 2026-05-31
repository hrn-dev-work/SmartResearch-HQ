#!/usr/bin/env bash
# Block commits that stage secret files or key-like strings.
# Called from .githooks/pre-commit. Install: bash scripts/install-git-hooks.sh

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

bad_staged=$(
  git diff --cached --name-only --diff-filter=AM \
    | grep -iE '(^|/)\.env(\.|$)|credentials\.json|service-account.*\.json|\.pem$|\.key$|id_rsa' \
    | grep -vE '\.example$|\.env\.example$' || true
)
if [[ -n "$bad_staged" ]]; then
  echo "pre-commit: refuse to commit secret-like files:" >&2
  echo "$bad_staged" >&2
  echo "Add to .gitignore and use .env.example (keys only, no values)." >&2
  exit 1
fi

if command -v gitleaks >/dev/null 2>&1; then
  gitleaks protect --staged --verbose --redact --config "$ROOT/.gitleaks.toml"
  exit 0
fi

# Fallback when gitleaks is not installed locally
if git diff --cached | grep -iE '(AKIA[0-9A-Z]{16}|ghp_[a-zA-Z0-9]{20,}|gho_[a-zA-Z0-9]{20,}|sk-[a-zA-Z0-9]{20,}|xoxb-[a-zA-Z0-9-]+)' \
  | grep -viE 'smartresearch|test-key|example|placeholder' | grep -q .; then
  echo "pre-commit: staged diff may contain a secret." >&2
  echo "Install gitleaks (brew install gitleaks) or remove the value before committing." >&2
  exit 1
fi

echo "pre-commit: secret check OK (install gitleaks for full staged scan)"
