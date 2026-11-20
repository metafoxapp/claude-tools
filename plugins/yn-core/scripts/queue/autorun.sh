#!/usr/bin/env bash
# Usage: autorun.sh on [N] | off | status
# Controls the Stop hook. The flag file holds the maximum number of times the
# hook may push Claude to continue (default 20); the hook also stops by itself
# when a continuation made no progress.
set -euo pipefail
. "$(dirname "$0")/common.sh"
yn_require_queue

flag="$YN_QUEUE_DIR/.autorun"
case "${1:-status}" in
  on)  echo "${2:-20}" > "$flag"; rm -f "$flag.last"; echo "autorun ON (max ${2:-20} continuations)" ;;
  off) rm -f "$flag" "$flag.last"; echo "autorun off" ;;
  status) if [ -f "$flag" ]; then echo "autorun ON ($(cat "$flag") left)"; else echo "autorun off"; fi ;;
  *) yn_die "usage: autorun.sh on [N] | off | status" ;;
esac
