#!/usr/bin/env bash
# Portfolio E2E smoke (no Docker). Usage: bash scripts/smoke-portfolio-e2e.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
API="${API_BASE:-http://127.0.0.1:8000/api/v1}"

echo "== portfolio E2E smoke =="
echo "API: $API"

health="$(curl -sf "$API/health")"
echo "health: $health"
echo "$health" | grep -q '"mode":"portfolio"'

job="$(curl -sf -X POST "$API/research" \
  -H 'Content-Type: application/json' \
  -d '{"shopee_shop_url":"https://shopee.sg/shop/smoke","seller_display_name":"Smoke"}')"
job_id="$(echo "$job" | python3 -c "import sys,json; print(json.load(sys.stdin)['job_id'])")"
echo "job_id: $job_id"

items="$(curl -sf "$API/research/$job_id/items")"
item_id="$(echo "$items" | python3 -c "import sys,json; print(json.load(sys.stdin)['items'][0]['item_id'])")"
candidate_id="$(echo "$items" | python3 -c "import sys,json; print(json.load(sys.stdin)['items'][0]['candidates'][0]['candidate_id'])")"
url="$(echo "$items" | python3 -c "import sys,json; print(json.load(sys.stdin)['items'][0]['shopee_item_url'])")"
test -n "$url"
echo "shopee_item_url: $url"

curl -sf -X POST "$API/review/$item_id/decide" \
  -H 'Content-Type: application/json' \
  -d "{\"candidate_id\":\"$candidate_id\"}" >/dev/null

export_result="$(curl -sf -X POST "$API/research/$job_id/export")"
echo "export: $export_result"
echo "$export_result" | grep -q '"exported_count":1'

echo "portfolio E2E smoke OK"
