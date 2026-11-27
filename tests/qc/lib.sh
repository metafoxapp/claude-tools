#!/usr/bin/env bash
# Tiny test helpers for yn-qc. Source from test files.
PLUGIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../plugins/yn-qc" 2>/dev/null && pwd)"
[ -n "$PLUGIN" ] || PLUGIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/plugins/yn-qc"
CK="$PLUGIN/scripts/checklist"
FAILS=0

pass() { echo "  ok   $*"; }
fail() { echo "  FAIL $*"; FAILS=$((FAILS + 1)); }
assert_eq() { # <expected> <actual> <msg>
  if [ "$1" = "$2" ]; then pass "$3"; else fail "$3 (expected '$1', got '$2')"; fi
}
assert_contains() { # <haystack> <needle> <msg>
  case "$1" in *"$2"*) pass "$3" ;; *) fail "$3 (missing '$2')" ;; esac
}
tmpdir() { mktemp -d "${TMPDIR:-/tmp}/yn-qc-test.XXXXXX"; }
