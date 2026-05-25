#!/usr/bin/env bash
# Gentle guard: very broad "implement everything" prompts → nudge to WBS (beforeSubmitPrompt).
set -euo pipefail

input=$(cat)
prompt=$(printf '%s' "$input" | python3 -c "import json,sys; print(json.load(sys.stdin).get('prompt',''))")

allow='{"continue": true}'

# Only nudge on short, vague mega-requests (not blocking long detailed prompts)
len=${#prompt}
if [ "$len" -gt 120 ]; then
  echo "$allow"
  exit 0
fi

if printf '%s' "$prompt" | python3 -c "
import re, sys
p = sys.stdin.read()
patterns = [
    r'全部.{0,12}(実装|作って|直して)',
    r'すべて.{0,12}(実装|作って)',
    r'(entire|whole)\s+(codebase|project|repo)',
    r'everything\s+implement',
    r'フル実装',
    r'丸ごと実装',
]
if any(re.search(x, p, re.I) for x in patterns):
    sys.exit(0)
sys.exit(1)
"; then
  python3 -c "import json; print(json.dumps({
    'continue': False,
    'user_message': '依頼が広すぎるため一度止めました。docs/wbs-roadmap.md の未完了タスク ID を1つ指定するか、「〇〇ファイルの△△だけ」と狭めて再送してください。AGENTS.md に既定の進め方があります。'
  }, ensure_ascii=False))"
  exit 0
fi

echo "$allow"
exit 0
