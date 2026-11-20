#!/usr/bin/env bash
# status.sh and init.sh: must work on an empty queue (regression) and a populated one.
set -u
. "$(dirname "$0")/lib.sh"

repo=$(new_repo); cd "$repo" || exit 1

echo "init"
out=$(bash "$Q/init.sh" --preset generic 2>&1); assert_eq "0" "$?" "init succeeds"
bash "$Q/init.sh" --preset generic >/dev/null 2>&1; assert_eq "0" "$?" "init is idempotent"
QD="$repo/.yn/queue"
for s in inbox ready doing review failed done log bin; do [ -d "$QD/$s" ] || fail "missing $s/"; done
[ -x "$QD/bin/worker.sh" ] && pass "worker.sh copied to bin/" || fail "bin/worker.sh missing"
assert_eq "1" "$(grep -cxF '.yn/queue/*' .gitignore)" ".gitignore entry added once"
assert_eq "laravel" "$(cd "$repo" && echo '{"require":{"laravel/framework":"^11"}}' > composer.json && bash "$Q/detect-stack.sh")" "detects laravel"
rm -f composer.json

echo "status: empty queue"
out=$(bash "$Q/status.sh" 2>&1); rc=$?
assert_eq "0" "$rc" "exit 0 on empty queue"
case "$out" in *"inbox 0 | ready 0"*) pass "counts printed" ;; *) fail "counts missing: $out" ;; esac
case "$out" in *"Autorun: off"*) pass "autorun line printed" ;; *) fail "autorun line missing" ;; esac

echo "status: populated"
mk_task "$QD/ready" T-0001 app; mk_task "$QD/ready" T-0002 tests; mk_task "$QD/review" T-0003 app
mk_task "$QD/inbox" T-0004 ""
bash "$Q/autorun.sh" on 7 >/dev/null
out=$(bash "$Q/status.sh" 2>&1); rc=$?
assert_eq "0" "$rc" "exit 0 when populated"
case "$out" in *"ready 2"*"review 1"*) pass "state counts" ;; *) fail "state counts: $out" ;; esac
echo "$out" | grep -Eq '^app +1 +0 +1 +0' && pass "group row for app" || fail "app row: $out"
case "$out" in *"Autorun: ON (remaining continuations: 7)"*) pass "autorun shown" ;; *) fail "autorun not shown" ;; esac
case "$out" in *"Inbox waiting for triage: 1"*) pass "inbox hint" ;; *) fail "inbox hint missing" ;; esac

rm -rf "$repo"
[ "$FAILS" -eq 0 ]
