#!/usr/bin/env bash
# diff_user_edits.py: report hand edits in the Checklist sheet against data.py.
set -u
. "$(dirname "$0")/lib.sh"
DIFF="$CK/diff_user_edits.py"
DATA="$PLUGIN/templates/checklist/example_data.py"
T=$(tmpdir); trap 'rm -rf "$T"' EXIT

python3 "$CK/build_checklist.py" "$DATA" "$T/c.xlsx" >/dev/null 2>&1 || fail "build example"

echo "diff: no edits"
out=$(python3 "$DIFF" "$T/c.xlsx" "$DATA" 2>&1); rc=$?
assert_eq "0" "$rc" "exit 0"
assert_contains "$out" "0 TC(s) changed by the user." "no changes"

echo "diff: hand edits"
python3 - "$T/c.xlsx" <<'PY'
import sys
from openpyxl import load_workbook
wb = load_workbook(sys.argv[1]); ws = wb["Checklist"]
rows = {ws.cell(r, 1).value: r for r in range(3, ws.max_row + 1)}
ws.cell(rows["SHP-002"], 10).value = "PASS"
ws.cell(rows["SHP-003"], 12).value = "Looks odd on mobile"
ws.cell(rows["SHP-004"], 10).value = None
ws.insert_rows(5)
ws.cell(5, 1).value = "ABC-1"; ws.cell(5, 10).value = "FAIL"
ws.insert_rows(6)
wb.save(sys.argv[1])
PY
out=$(python3 "$DIFF" "$T/c.xlsx" "$DATA" 2>&1); rc=$?
assert_eq "0" "$rc" "exit 0 with edits"
assert_contains "$out" "SHP-002: FAIL -> PASS" "status change"
assert_contains "$out" "SHP-003: NOT TESTED -> NOT TESTED  (tester/notes changed)" "notes-only change"
assert_contains "$out" "SHP-004: BLOCKED -> NOT TESTED" "blank status is NOT TESTED"
assert_contains "$out" "3 TC(s) changed by the user." "count"
assert_contains "$out" "RESULTS" "RESULTS block"
assert_contains "$out" '"SHP-003": ("NOT TESTED", "", "Looks odd on mobile")' "RESULTS entry"
case "$out" in *ABC-1*) fail "foreign row ignored" ;; *) pass "foreign row ignored" ;; esac
changes="${out%%TC(s) changed*}"
case "$changes" in *SHP-001*) fail "unchanged TC not listed" ;; *) pass "unchanged TC not listed" ;; esac

echo "diff: deleted row"
python3 - "$T/c.xlsx" <<'PY'
import sys
from openpyxl import load_workbook
wb = load_workbook(sys.argv[1]); ws = wb["Checklist"]
for r in range(3, ws.max_row + 1):
    if ws.cell(r, 1).value == "SHP-004":
        ws.delete_rows(r); break
wb.save(sys.argv[1])
PY
out=$(python3 "$DIFF" "$T/c.xlsx" "$DATA" 2>&1)
assert_contains "$out" "NOTE: SHP-004 not found in sheet, kept existing result" "NOTE for deleted row"
assert_contains "$out" '"SHP-004": ("BLOCKED", "Linh", "Waiting on Q-SHP-01")' "deleted row kept in RESULTS"
assert_contains "$out" '"SHP-001": ("PASS", "Linh", "Round 1.")' "unchanged TC stays in RESULTS"

echo "diff: errors"
out=$(python3 "$DIFF" "$T/nope.xlsx" "$DATA" 2>&1); rc=$?
assert_eq "2" "$rc" "missing xlsx exit 2"
assert_contains "$out" "ERROR:" "missing xlsx message"
case "$out" in *Traceback*) fail "no traceback (missing)" ;; *) pass "no traceback (missing)" ;; esac
echo junk > "$T/bad.xlsx"
out=$(python3 "$DIFF" "$T/bad.xlsx" "$DATA" 2>&1); rc=$?
assert_eq "2" "$rc" "unreadable xlsx exit 2"
case "$out" in *Traceback*) fail "no traceback (bad)" ;; *) pass "no traceback (bad)" ;; esac
python3 -c "
from openpyxl import Workbook
w=Workbook(); w.active.title='Other'; w.save('$T/nosheet.xlsx')"
out=$(python3 "$DIFF" "$T/nosheet.xlsx" "$DATA" 2>&1); rc=$?
assert_eq "2" "$rc" "no Checklist sheet exit 2"
assert_contains "$out" "ERROR:" "no sheet message"
printf 'PROJECT = {}\n' > "$T/bad_data.py"
out=$(python3 "$DIFF" "$T/c.xlsx" "$T/bad_data.py" 2>&1); rc=$?
assert_eq "2" "$rc" "bad data exit 2"
assert_contains "$out" "ERROR:" "bad data message"

exit $FAILS
