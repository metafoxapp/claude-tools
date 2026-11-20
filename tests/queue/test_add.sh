#!/usr/bin/env bash
# add.sh: unique sequential ids under concurrency; input validation.
set -u
. "$(dirname "$0")/lib.sh"

repo=$(new_repo); cd "$repo" || exit 1
bash "$Q/init.sh" --preset generic >/dev/null
QD="$repo/.yn/queue"

task() { printf -- '---\nid: T-XXXX\ntitle: %s\ngroup:\npriority: 3\n---\n## Acceptance\n- [ ] x\n' "$1"; }

echo "add: ids"
p=$(task first | bash "$Q/add.sh")
assert_eq "T-0001.md" "$(basename "$p")" "first id is T-0001"
assert_eq "T-0001" "$(awk -F': ' '/^id:/{print $2; exit}' "$p")" "id line rewritten"

echo "add: 8 concurrent adds"
for n in 1 2 3 4 5 6 7 8; do ( task "c$n" | bash "$Q/add.sh" >/dev/null ) & done
wait
assert_eq "9" "$(ls "$QD/inbox" | wc -l | tr -d ' ')" "9 files in inbox"
assert_eq "9" "$(ls "$QD/inbox" | sort -u | wc -l | tr -d ' ')" "ids unique"
[ ! -d "$QD/.lock" ] && pass "lock released" || fail "lock left behind"

echo "add: validation"
printf '' | bash "$Q/add.sh" >/dev/null 2>&1; assert_eq "1" "$?" "empty stdin rejected"
printf 'no front matter\n' | bash "$Q/add.sh" >/dev/null 2>&1; assert_eq "1" "$?" "missing front matter rejected"
printf -- '---\ntitle:\n---\n' | bash "$Q/add.sh" >/dev/null 2>&1; assert_eq "1" "$?" "empty title rejected"

rm -rf "$repo"
[ "$FAILS" -eq 0 ]
