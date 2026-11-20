#!/usr/bin/env bash
# worker.sh end-to-end with a fake `claude`: success path, independent verify,
# retry then failed, missing verify command, dry-run.
set -u
. "$(dirname "$0")/lib.sh"

repo=$(new_repo); cd "$repo" || exit 1
bash "$Q/init.sh" --preset generic >/dev/null
QD="$repo/.yn/queue"

# Fake claude: finds the task id in the prompt ($2) and commits a file for it,
# unless FAKE_NOCOMMIT=1.
fake="$repo/.fake-claude"
cat > "$fake" <<'EOF'
#!/usr/bin/env bash
id=$(printf '%s' "$2" | grep -o 'T-[0-9]\{4\}' | tail -n 1)
[ "${FAKE_NOCOMMIT:-0}" = 1 ] && exit 0
echo "$id" > "$id.txt"; git add -A; git commit -qm "$id: done"
EOF
chmod +x "$fake"
export YN_CLAUDE_BIN="$fake"

# The generic preset has empty group verify commands; tasks carry their own `verify:`.

echo "worker: dry-run"
mk_task "$QD/ready" T-0001 app 3 "" "true"
out=$(bash "$Q/worker.sh" app --dry-run)
case "$out" in *T-0001*) pass "dry-run names next task" ;; *) fail "dry-run output: $out" ;; esac
assert_eq "1" "$(ls "$QD/ready" | wc -l | tr -d ' ')" "dry-run claims nothing"

echo "worker: success path"
out=$(bash "$Q/worker.sh" app --max-tasks 3)
assert_eq "T-0001.md" "$(ls "$QD/review")" "task moved to review"
assert_eq "T-0001: done" "$(git -C "$repo/.claude/worktrees/q-app" log -1 --format=%s)" "commit on worktree branch"
assert_eq "main" "$(git -C "$repo" branch --show-current)" "main checkout untouched"
grep -q '^## Evidence' "$QD/review/T-0001.md" && pass "evidence appended" || fail "no evidence section"
[ ! -d "$QD/.worker-app.lock" ] && pass "worker lock released" || fail "worker lock left"

echo "worker: verify fails -> retry -> failed"
mk_task "$QD/ready" T-0002 app 3 "" "false"
bash "$Q/worker.sh" app --max-tasks 1 >/dev/null
assert_eq "T-0002.md" "$(ls "$QD/ready")" "first failure goes back to ready"
bash "$Q/worker.sh" app --max-tasks 1 >/dev/null
assert_eq "T-0002.md" "$(ls "$QD/failed")" "second failure goes to failed"
grep -q '^## Failure' "$QD/failed/T-0002.md" && pass "failure noted" || fail "no failure section"

echo "worker: claude makes no commit -> not accepted even if verify passes"
mk_task "$QD/ready" T-0003 app 3 "" "true"
FAKE_NOCOMMIT=1 bash "$Q/worker.sh" app --max-tasks 1 >/dev/null
assert_eq "T-0003.md" "$(ls "$QD/ready")" "no commit means retry, not review"

echo "worker: no verify command"
rm -f "$QD"/ready/*.md
mk_task "$QD/ready" T-0004 docs 3
bash "$Q/worker.sh" docs --max-tasks 1 >/dev/null
assert_eq "T-0004.md" "$(ls "$QD/failed" | grep T-0004)" "task without verify fails fast"

rm -rf "$repo"
[ "$FAILS" -eq 0 ]
