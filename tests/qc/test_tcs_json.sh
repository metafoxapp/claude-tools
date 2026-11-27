#!/usr/bin/env bash
# tcs_json.py: export tcs.json and fold an automated run summary back into RESULTS.
set -u
. "$(dirname "$0")/lib.sh"
TJ="$CK/tcs_json.py"
DATA="$PLUGIN/templates/checklist/example_data.py"
T=$(tmpdir); trap 'rm -rf "$T"' EXIT

echo "tcs: export"
out=$(python3 "$TJ" export "$DATA" "$T/tcs.json" 2>&1); rc=$?
assert_eq "0" "$rc" "export exit 0"
assert_contains "$out" "(5 tests)" "export count"
assert_eq "SHP-001" "$(jq -r '.tests[0].id' "$T/tcs.json")" "first id"
assert_eq "5" "$(jq '.tests|length' "$T/tcs.json")" "one entry per TC"
assert_eq "Critical" "$(jq -r '.tests[0].priority' "$T/tcs.json")" "priority exported"
assert_eq "2" "$(jq '.tests[0].steps|length' "$T/tcs.json")" "steps as a list"

echo "tcs: results"
cat > "$T/s.json" <<'JSON'
{"results": [{"id": "SHP-002", "status": "passed"}, {"id": "SHP-003", "status": "flaky", "message": "timeout"},
             {"id": "SHP-004", "status": "passed"}, {"id": "SHP-005", "status": "skipped"},
             {"id": "NOPE-1", "status": "failed"}]}
JSON
out=$(python3 "$TJ" results "$DATA" "$T/s.json" --tester "CI run 7" 2>&1); rc=$?
assert_eq "0" "$rc" "results exit 0"
assert_contains "$out" "SHP-002: FAIL -> PASS" "passed maps to PASS"
assert_contains "$out" '"SHP-003": ("NOT TESTED", "CI run 7", "Flaky: timeout")' "flaky maps to NOT TESTED"
assert_contains "$out" '"SHP-004": ("BLOCKED"' "pending TC stays BLOCKED"
assert_contains "$out" "NOTE: NOPE-1" "unknown id noted"
case "$out" in *'"SHP-005"'*) fail "skipped leaves TC untouched" ;; *) pass "skipped leaves TC untouched" ;; esac
assert_contains "$out" '"SHP-001": ("PASS", "Linh", "Round 1.")' "existing results kept"

echo "tcs: errors"
echo '{}' > "$T/bad.json"
out=$(python3 "$TJ" results "$DATA" "$T/bad.json" --tester x 2>&1); rc=$?
assert_eq "2" "$rc" "bad summary exit 2"
assert_contains "$out" "ERROR:" "bad summary message"
python3 "$TJ" results "$DATA" "$T/s.json" >/dev/null 2>&1; assert_eq "2" "$?" "--tester required"

echo "build: priority counts and pending rule"
out=$(python3 "$CK/build_checklist.py" "$DATA" "$T/c.xlsx" 2>&1)
assert_contains "$out" "Critical: PASS 1, BLOCKED 1" "builder prints counts per priority"
sed 's/"SHP-004": ("BLOCKED"/"SHP-004": ("PASS"/' "$DATA" > "$T/pend.py"
out=$(python3 "$CK/build_checklist.py" "$T/pend.py" "$T/p.xlsx" 2>&1); rc=$?
assert_eq "2" "$rc" "PASS on a pending TC rejected"
assert_contains "$out" "SHP-004: PASS while the expected result is still '(pending Q-" "pending error names the TC"
python3 - "$T/c.xlsx" > "$T/sum.txt" <<'PY'
import sys
from openpyxl import load_workbook
ws = load_workbook(sys.argv[1])["Summary"]
print("|".join(str(c.value) for row in ws.iter_rows() for c in row if c.value is not None))
PY
assert_contains "$(cat "$T/sum.txt")" "Priority|# TC|PASS" "Summary has a priority table"
assert_contains "$(cat "$T/sum.txt")" "Release gate" "Summary states the release gate"

exit $FAILS
