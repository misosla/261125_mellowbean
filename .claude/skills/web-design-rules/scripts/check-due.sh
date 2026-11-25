#!/usr/bin/env bash
# SessionStart hook: prints a reminder when the rules are INTERVAL_DAYS old or more.
INTERVAL_DAYS=3

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || exit 0
last="$(head -c 10 "$dir/last-updated.txt" 2>/dev/null)"
last_s="$(date -d "${last:-1970-01-01}" +%s 2>/dev/null)" || last_s=0
today_s="$(date -d "$(date +%F)" +%s)"
days=$(( (today_s - last_s) / 86400 ))

[ "$days" -lt "$INTERVAL_DAYS" ] && exit 0

cat <<JSON
{"systemMessage":"웹디자인 규칙을 갱신할 때가 되었습니다. 첫 요청을 처리한 뒤 정리할게요.","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"The user asked for the web-design-rules skill to be refreshed every ${INTERVAL_DAYS} days, and it is now due. First complete the user's request. Then, in the same turn, follow .claude/skills/web-design-rules/references/update.md to update SKILL.md and last-updated.txt, and report the changes briefly in Korean."}}
JSON
