#!/usr/bin/env bash
# Stop hook: no-op without the flag; bounded, progress-checked continuation with it.
set -u
. "$(dirname "$0")/lib.sh"

command -v jq >/dev/null 2>&1 || { echo "  skip (jq not installed)"; exit 0; }

repo=$(new_repo); cd "$repo" || exit 1
bash "$Q/init.sh" --preset generic >/dev/null
QD="$repo/.yn/queue"
run_hook() { echo '{"stop_hook_active": false}' | CLAUDE_PROJECT_DIR="$repo" bash "$HOOK"; }

echo "hook: no flag"
mk_task "$QD/ready" T-0001 app; mk_task "$QD/ready" T-0002 app; mk_task "$QD/ready" T-0003 app
out=$(run_hook); assert_eq "" "$out" "silent without .autorun"

echo "hook: flag on, tasks ready"
bash "$Q/autorun.sh" on 5 >/dev/null
out=$(run_hook)
assert_eq "block" "$(echo "$out" | jq -r .decision)" "blocks stop while tasks remain"
assert_eq "4" "$(cat "$QD/.autorun")" "counter decremented"

echo "hook: no progress stops it"
out=$(run_hook)
assert_eq "" "$out" "second call with unchanged ready count does not block"
[ ! -f "$QD/.autorun" ] && pass "flag removed" || fail "flag still present"

echo "hook: progress keeps it going"
bash "$Q/autorun.sh" on 5 >/dev/null
run_hook >/dev/null
bash "$Q/claim.sh" app >/dev/null
out=$(run_hook)
assert_eq "block" "$(echo "$out" | jq -r .decision)" "ready count shrank, continues"

echo "hook: queue empty / counter exhausted"
rm -f "$QD"/ready/*.md
out=$(run_hook); assert_eq "" "$out" "no ready tasks: silent"
[ ! -f "$QD/.autorun" ] && pass "flag cleaned when queue empty" || fail "flag not cleaned"
mk_task "$QD/ready" T-0010 app
echo 0 > "$QD/.autorun"
out=$(run_hook); assert_eq "" "$out" "counter 0: silent"

echo "hook: outside a git repo"
plain=$(mktemp -d)
out=$(echo '{}' | CLAUDE_PROJECT_DIR="$plain" bash "$HOOK"); assert_eq "" "$out" "no-op outside git"

rm -rf "$repo" "$plain"
[ "$FAILS" -eq 0 ]
