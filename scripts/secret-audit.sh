#!/usr/bin/env bash
# Portable secret audit (repo-security-setup). Best-practice baseline.
# Usage: bash scripts/secret-audit.sh [--strict]
#
# Exit 0 = clean. Exit 1 = findings (warnings fail under --strict).
# CI must run with --strict. Also requires gitleaks-action + Trivy secret.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

STRICT=0
if [[ "${1:-}" == "--strict" ]]; then
  STRICT=1
fi

issues=0
warn() { echo "WARN: $*" >&2; [[ "$STRICT" -eq 1 ]] && issues=$((issues + 1)) || true; }
fail() { echo "FAIL: $*" >&2; issues=$((issues + 1)); }

echo "== secret audit =="

echo "-- tracked secret-like paths --"
tracked_secret_files=$(
  git ls-files | grep -iE \
    '(^|/)\.env(\.|$)|(^|/)(credentials|service-account[^/]*)\.json$|\.(pem|p12|pfx|key)$|(^|/)id_(rsa|ed25519)|(^|/)\.pypirc$' \
    | grep -vE '\.example$|\.env\.example$|\.sample$|\.template$|\.npmrc$' || true
)
if [[ -n "$tracked_secret_files" ]]; then
  fail "Secret-like files are tracked by git:"
  echo "$tracked_secret_files" >&2
else
  echo "OK: no secret-like paths tracked (except examples)"
fi

echo "-- git history (env / credentials paths) --"
history_paths=$(
  git log --all --pretty=format: --name-only -- \
    '.env' '.env.local' '.env.production' '.env.development' \
    'credentials.json' 'service-account.json' '*.pem' 2>/dev/null \
    | sort -u | grep -v '^$' || true
)
if [[ -n "$history_paths" ]]; then
  fail "Secret paths appear in git history (rotate keys + purge before public):"
  echo "$history_paths" >&2
else
  echo "OK: no common secret paths in commit history"
fi

echo "-- git history (key-like strings pickaxe) --"
pickaxe_hits=0
# Build PEM armor markers at runtime so this source does not embed
# "BEGIN … PRIVATE KEY" literals (naive pre-commit greps false-positive).
pem_armor() { printf 'BEGIN %s PRIVATE KEY' "$1"; }
needles=(
  'AKIA'
  'sk-'
  'sk_live'
  'ghp_'
  'gho_'
  'ghu_'
  'ghs_'
  'xoxb-'
  'xoxp-'
  "$(pem_armor OPENSSH)"
  "$(pem_armor RSA)"
)
for needle in "${needles[@]}"; do
  if git log --all -S "$needle" --pretty=format: 2>/dev/null | grep -q .; then
    warn "History may touch '$needle' — review: git log -p --all -S \"$needle\" | head"
    pickaxe_hits=$((pickaxe_hits + 1))
  fi
done
if [[ "$pickaxe_hits" -eq 0 ]]; then
  echo "OK: no common high-signal markers in history pickaxe"
fi

echo "-- hardcoded secrets in source (heuristic) --"
source_dirs=()
while IFS= read -r d; do
  [[ -n "$d" ]] && source_dirs+=("$d")
done < <(
  for d in src app backend frontend apps packages server api lib cmd internal; do
    [[ -d "$d" ]] && echo "$d"
  done
)
if [[ ${#source_dirs[@]} -eq 0 ]]; then
  # Docs-only / empty trees: not a finding; CI still runs gitleaks + Trivy.
  echo "OK: no common source roots — content scan deferred to gitleaks/Trivy"
else
  secret_pattern='(api[_-]?key|secret[_-]?key|access[_-]?key|password|passwd|private[_-]?key|client_secret)\s*[:=]\s*["'\''`][^"'\'']{8,}'
  hardcoded=$(
    # shellcheck disable=SC2086
    grep -rniE "$secret_pattern" "${source_dirs[@]}" 2>/dev/null \
      | grep -viE 'test-key|example|dummy|placeholder|your[_-]?api|changeme|process\.env|settings\.|getenv|os\.environ|env\.|import\.meta\.env' \
      | grep -viE '/vendor/|/node_modules/|/\.venv/|/site-packages/|/dist/|/build/|/\.next/' \
      | grep -viE 'accessKey|access_key|DB_PASSWORD|POSTGRES_PASSWORD|PGPASSWORD|MYSQL_PASSWORD|ROOT_PASSWORD' \
      || true
  )
  if [[ -n "$hardcoded" ]]; then
    fail "Possible hardcoded secrets in source:"
    echo "$hardcoded" >&2
  else
    echo "OK: no obvious hardcoded secrets in: ${source_dirs[*]}"
  fi
fi

echo "-- gitleaks (local optional; CI uses gitleaks-action) --"
if command -v gitleaks >/dev/null 2>&1; then
  gitleaks_args=(detect --source "$ROOT" --no-banner --redact --verbose)
  if [[ -f "$ROOT/.gitleaks.toml" ]]; then
    gitleaks_args+=(--config "$ROOT/.gitleaks.toml")
  fi
  if gitleaks "${gitleaks_args[@]}" 2>&1; then
    echo "OK: gitleaks found no leaks"
  else
    fail "gitleaks reported potential leaks (see above)"
  fi
else
  echo "SKIP: gitleaks not installed locally (required in CI)"
fi

echo "== secret audit done =="
if [[ "$issues" -gt 0 ]]; then
  echo "Result: $issues issue(s) — fix or rotate before publish." >&2
  exit 1
fi
echo "Result: clean"
exit 0
