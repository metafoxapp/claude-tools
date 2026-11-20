#!/usr/bin/env bash
# claim.sh: priority order, dependencies, and exclusive claims under contention.
set -u
. "$(dirname "$0")/lib.sh"

repo=$(new_repo); cd "$repo" || exit 1
bash "$Q/init.sh" --preset generic >/dev/null
QD="$repo/.yn/queue"

echo "claim: priority and dependencies"
mk_task "$QD/ready" T-0001 app 3
mk_task "$QD/ready" T-0002 app 1
mk_task "$QD/ready" T-0003 app 1 "T-0001"
got=$(bash "$Q/claim.sh" app | xargs basename)
assert_eq "T-0002.md" "$got" "lowest priority number first"
got=$(bash "$Q/claim.sh" app | xargs basename)
assert_eq "T-0001.md" "$got" "dependent task waits for its dependency"
bash "$Q/claim.sh" app >/dev/null 2>&1; rc=$?
assert_eq "3" "$rc" "T-0003 blocked while T-0001 is only in doing (exit 3)"
bash "$Q/move.sh" T-0001 review >/dev/null
got=$(bash "$Q/claim.sh" app | xargs basename)
assert_eq "T-0003.md" "$got" "same-group dependency in review unblocks"

echo "claim: other groups untouched"
mk_task "$QD/ready" T-0004 tests 3
bash "$Q/claim.sh" app >/dev/null 2>&1; rc=$?
assert_eq "3" "$rc" "no eligible task in app"
assert_eq "1" "$(ls "$QD/ready" | wc -l | tr -d ' ')" "tests task still ready"

echo "claim: 4 racing workers, 20 tasks"
rm -f "$QD"/*/T-*.md
i=1; while [ "$i" -le 20 ]; do mk_task "$QD/ready" "$(printf 'T-%04d' "$i")" app 3; i=$((i + 1)); done
out=$(mktemp -d)
for w in 1 2 3 4; do
  ( while f=$(bash "$Q/claim.sh" app 2>/dev/null); do basename "$f" >> "$out/w$w"; done ) &
done
wait
total=$(cat "$out"/w* | wc -l | tr -d ' ')
uniq_n=$(cat "$out"/w* | sort -u | wc -l | tr -d ' ')
assert_eq "20" "$total" "all 20 tasks claimed"
assert_eq "20" "$uniq_n" "no task claimed twice"
assert_eq "20" "$(ls "$QD/doing" | wc -l | tr -d ' ')" "doing/ holds 20 files"

rm -rf "$repo" "$out"
[ "$FAILS" -eq 0 ]
