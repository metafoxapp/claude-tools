#!/usr/bin/env bash
# Usage: claim.sh <group> [task-id]
# Atomically moves the next eligible task of <group> from ready/ to doing/ and
# prints its new path. Exit 3 when no task is eligible.
# Atomicity: mv is a rename on the same filesystem, so when two workers race for
# one task, exactly one rename succeeds and the other fails with ENOENT.
# YN_PEEK=1 prints the next eligible task without claiming it.
set -euo pipefail
. "$(dirname "$0")/common.sh"
yn_require_queue

group="${1:?usage: claim.sh <group> [task-id]}"
want="${2:-}"

# A dependency is satisfied when it is done, or when it is in review inside the
# same group (same branch, so its commits are already in this worktree).
deps_ok() {
  local d
  for d in $(fm_list "$1" depends_on); do
    [ -f "$YN_QUEUE_DIR/done/$d.md" ] && continue
    if [ -f "$YN_QUEUE_DIR/review/$d.md" ] && [ "$(fm_get "$YN_QUEUE_DIR/review/$d.md" group)" = "$group" ]; then
      continue
    fi
    return 1
  done
  return 0
}

candidates=$(
  for f in "$YN_QUEUE_DIR"/ready/*.md; do
    [ -e "$f" ] || continue
    [ "$(fm_get "$f" group)" = "$group" ] || continue
    id=$(basename "$f" .md)
    if [ -n "$want" ] && [ "$id" != "$want" ]; then continue; fi
    p=$(fm_get "$f" priority); p=${p:-5}
    printf '%s\t%s\t%s\n' "$p" "$id" "$f"
  done | sort -t "$(printf '\t')" -k1,1n -k2,2
)

while IFS="$(printf '\t')" read -r _prio id f; do
  [ -n "${f:-}" ] || continue
  deps_ok "$f" || continue
  if [ "${YN_PEEK:-0}" = "1" ]; then echo "$f"; exit 0; fi
  if mv "$f" "$YN_QUEUE_DIR/doing/$id.md" 2>/dev/null; then
    echo "$YN_QUEUE_DIR/doing/$id.md"
    exit 0
  fi
done <<EOF
$candidates
EOF

exit 3
