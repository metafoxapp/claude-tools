#!/usr/bin/env bash
# Stop hook for yn-core. Must be a cheap no-op in every project that does not use
# the queue: it only acts when .yn/queue/.autorun exists.
#
# Loop protection (replaces the usual stop_hook_active check, which would allow
# only ONE continuation): the flag file holds a bounded counter, and a
# continuation is only forced while the number of ready tasks keeps shrinking.
# Claude Code additionally caps consecutive blocks without tool calls.
cat >/dev/null
command -v jq >/dev/null 2>&1 || exit 0

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
git rev-parse --git-common-dir >/dev/null 2>&1 || exit 0
# shellcheck source=../scripts/queue/common.sh
. "$(dirname "$0")/../scripts/queue/common.sh"

flag="$YN_QUEUE_DIR/.autorun"
[ -f "$flag" ] || exit 0

ready=$(ls "$YN_QUEUE_DIR"/ready/*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$ready" -eq 0 ]; then rm -f "$flag" "$flag.last"; exit 0; fi

left=$(cat "$flag" 2>/dev/null || echo 0)
case "$left" in ''|*[!0-9]*) left=0 ;; esac
if [ "$left" -le 0 ]; then rm -f "$flag" "$flag.last"; exit 0; fi

if [ -f "$flag.last" ]; then
  last=$(cat "$flag.last")
  if [ "$ready" -ge "$last" ]; then rm -f "$flag" "$flag.last"; exit 0; fi
fi

echo $((left - 1)) > "$flag"
echo "$ready" > "$flag.last"

reason="Queue autorun: $ready task(s) still in .yn/queue/ready. Run /yn-core:queue-run for the next eligible task (claim it, implement, verify, commit, move it to review). Do not ask for confirmation."
jq -n --arg r "$reason" '{decision: "block", reason: $r}'
