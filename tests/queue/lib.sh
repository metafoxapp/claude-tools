#!/usr/bin/env bash
# Tiny test helpers. Source from test files.
PLUGIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../plugins/yn-core" && pwd)"
Q="$PLUGIN/scripts/queue"
HOOK="$PLUGIN/hooks/queue-stop.sh"
FAILS=0

pass() { echo "  ok   $*"; }
fail() { echo "  FAIL $*"; FAILS=$((FAILS + 1)); }
assert_eq() { # <expected> <actual> <msg>
  if [ "$1" = "$2" ]; then pass "$3"; else fail "$3 (expected '$1', got '$2')"; fi
}

# new_repo: creates a temp git repo with one commit on main, prints its path.
new_repo() {
  local d
  d=$(mktemp -d "${TMPDIR:-/tmp}/yn-test.XXXXXX")
  (
    cd "$d" && git init -q -b main && git config user.email t@t && git config user.name t
    echo base > base.txt && git add -A && git commit -qm base
  )
  echo "$d"
}

# mk_task <queue-state-dir> <id> <group> [priority] [depends_on] [verify]
mk_task() {
  cat > "$1/$2.md" <<EOF
---
id: $2
title: task $2
group: $3
priority: ${4:-3}
depends_on: [${5:-}]
touches: []
verify: ${6:-}
---
## Acceptance
- [ ] works
EOF
}
