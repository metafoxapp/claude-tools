#!/usr/bin/env bash
# Usage: status.sh
# Prints task counts per state and a group x state table.
set -euo pipefail
. "$(dirname "$0")/common.sh"
yn_require_queue

# find (not ls): `ls` fails on an empty dir, and with pipefail+set -e that would abort the script.
count() { find "$YN_QUEUE_DIR/$1" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' '; }

echo "Queue: $YN_QUEUE_DIR"
line=""
for s in $YN_STATES; do line="$line$s $(count "$s") | "; done
echo "${line% | }"
if [ -f "$YN_QUEUE_DIR/.autorun" ]; then
  echo "Autorun: ON (remaining continuations: $(cat "$YN_QUEUE_DIR/.autorun"))"
else
  echo "Autorun: off"
fi
echo

groups=$( { cfg_groups; for s in ready doing review failed; do
  for f in "$YN_QUEUE_DIR/$s"/*.md; do if [ -e "$f" ]; then fm_get "$f" group; fi; done
done; true; } | sed '/^$/d' | sort -u)

printf '%-18s %6s %6s %7s %7s\n' GROUP ready doing review failed
for g in $groups; do
  row=""
  for s in ready doing review failed; do
    n=0
    for f in "$YN_QUEUE_DIR/$s"/*.md; do
      [ -e "$f" ] || continue
      [ "$(fm_get "$f" group)" = "$g" ] && n=$((n + 1))
    done
    row="$row $n"
  done
  # shellcheck disable=SC2086
  set -- $row
  printf '%-18s %6s %6s %7s %7s\n' "$g" "$1" "$2" "$3" "$4"
done

inbox=$(count inbox)
[ "$inbox" -gt 0 ] && echo && echo "Inbox waiting for triage: $inbox"
exit 0
