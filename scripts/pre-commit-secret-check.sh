#!/usr/bin/env bash
# Block staged secret files / high-signal tokens. Default Level A control.
# Wire from .githooks / husky / scripts/install-git-hooks.sh, or:
#   cp scripts/pre-commit-secret-check.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

bad_staged=$(
  git diff --cached --name-only --diff-filter=AM \
    | grep -iE \
      '(^|/)\.env(\.|$)|(^|/)(credentials|service-account[^/]*)\.json$|\.(pem|p12|pfx|key)$|(^|/)id_(rsa|ed25519)' \
    | grep -vE '\.example$|\.env\.example$|\.sample$|\.template$' || true
)
if [[ -n "$bad_staged" ]]; then
  echo "pre-commit: refuse to commit secret-like files:" >&2
  echo "$bad_staged" >&2
  echo "Use .env.example (keys only) and keep secrets out of git." >&2
  exit 1
fi

if command -v gitleaks >/dev/null 2>&1; then
  cfg=()
  if [[ -f "$ROOT/.gitleaks.toml" ]]; then
    cfg=(--config "$ROOT/.gitleaks.toml")
  fi
  gitleaks protect --staged --verbose --redact "${cfg[@]}"
  exit 0
fi

# Heuristic only when gitleaks is missing. Skip tooling / docs lines that
# name token shapes without being live secrets (FP from secret-audit needles).
if git diff --cached | grep -iE \
  '(AKIA[0-9A-Z]{16}|ghp_[a-zA-Z0-9]{20,}|gho_[a-zA-Z0-9]{20,}|ghu_[a-zA-Z0-9]{20,}|sk_live_[a-zA-Z0-9]+|sk-[a-zA-Z0-9]{20,}|xoxb-[a-zA-Z0-9-]+|BEGIN (OPENSSH|RSA) PRIVATE KEY)' \
  | grep -viE 'example|placeholder|test-key|dummy|for needle|pem_armor|pickaxe|needles=\(|secret-audit|gitleaks' \
  | grep -q .; then
  echo "pre-commit: staged diff may contain a secret." >&2
  echo "Install gitleaks (preferred) or remove the value before committing." >&2
  exit 1
fi

echo "pre-commit: secret check OK (install gitleaks for full staged scan)"
