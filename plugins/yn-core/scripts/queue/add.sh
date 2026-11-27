#!/usr/bin/env bash
# Usage: add.sh < task.md
# Reads a complete task file (front matter + body) on stdin, allocates the next
# T-#### id under a lock, rewrites the `id:` line, stores it in inbox/ and
# prints the new path.
set -euo pipefail
. "$(dirname "$0")/common.sh"
yn_require_queue

tmp=$(mktemp "${TMPDIR:-/tmp}/yn-task.XXXXXX")
trap 'rm -f "$tmp"' EXIT
cat > "$tmp"
[ -s "$tmp" ] || yn_die "empty task on stdin"
[ "$(head -n 1 "$tmp")" = "---" ] || yn_die "task must start with front matter (---)"
[ -n "$(fm_get "$tmp" title)" ] || yn_die "front matter needs a non-empty 'title:'"

lock="$YN_QUEUE_DIR/.lock"
held=0
i=0
# The lock is owned by whoever creates $lock/owner with an exclusive (noclobber,
# O_EXCL) redirection. mkdir alone is not enough: some mkdir implementations
# report success when a concurrent caller created the directory first.
while [ "$i" -lt 100 ]; do
  mkdir "$lock" 2>/dev/null || true
  if (set -C; echo "$$" > "$lock/owner") 2>/dev/null; then held=1; break; fi
  sleep 0.1
  i=$((i + 1))
done
[ "$held" = 1 ] || yn_die "could not acquire $lock (stale lock? remove it if no add.sh is running)"
trap 'rm -f "$lock/owner"; rmdir "$lock" 2>/dev/null || true; rm -f "$tmp"' EXIT

max=$(ls "$YN_QUEUE_DIR"/*/T-*.md 2>/dev/null | sed -E 's/.*T-0*([0-9]+)\.md$/\1/' | sort -n | tail -n 1 || true)
next=$(( ${max:-0} + 1 ))
id=$(printf 'T-%04d' "$next")

out="$YN_QUEUE_DIR/inbox/$id.md"
awk -v id="$id" '
  NR == 1 { print; next }
  !done && /^id:/ { print "id: " id; done = 1; next }
  !done && /^---$/ { print "id: " id; done = 1 }
  { print }
' "$tmp" > "$out.part"
mv "$out.part" "$out"
echo "$out"
