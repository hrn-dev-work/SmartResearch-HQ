#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd $(dirname $0)/.. && pwd)
cd $ROOT
required=(scripts/validate-public-docs.sh scripts/check-staged-branch-scope.sh)
echo "== pr tooling: required scripts =="
for f in ${required[@]}; do [[ -f $f ]] || { echo MISSING: $f >&2; exit 1; }; done
echo "== pr tooling: public docs bilingual =="
bash scripts/validate-public-docs.sh README.md
echo "PR tooling self-check passed."
