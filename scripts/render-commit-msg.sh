#!/usr/bin/env bash
# Render bilingual commit message scaffold (English subject + EN/JA body separated by ---).
# Usage:
#   bash scripts/render-commit-msg.sh
#   bash scripts/render-commit-msg.sh feat spreadsheet "add export skeleton (WBS 2.3)"

set -euo pipefail

TYPE="${1:-type}"
SCOPE="${2:-scope}"
SUBJECT="${3:-short English summary}"

if [[ -n "${SCOPE}" && "${SCOPE}" != "scope" ]]; then
  HEADER="${TYPE}(${SCOPE}): ${SUBJECT}"
else
  HEADER="${TYPE}: ${SUBJECT}"
fi

cat <<EOF
${HEADER}

(English why — 1–2 concise sentences or bullets)

---

（日本語の why — 1〜2 文。簡潔に）

Refs #
EOF
