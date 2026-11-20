#!/usr/bin/env bash
# Usage: move.sh <task-id> <state>
# Moves a task to another state (inbox ready doing review failed done).
set -euo pipefail
. "$(dirname "$0")/common.sh"
yn_require_queue

id="${1:?usage: move.sh <task-id> <state>}"
to="${2:?usage: move.sh <task-id> <state>}"

case " $YN_STATES " in
  *" $to "*) ;;
  *) yn_die "unknown state '$to' (valid: $YN_STATES)" ;;
esac

src=$(task_file "$id") || yn_die "task $id not found"
dest="$YN_QUEUE_DIR/$to/$id.md"
[ "$src" = "$dest" ] && { echo "$dest"; exit 0; }
mv "$src" "$dest"
echo "$dest"
