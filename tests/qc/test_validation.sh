#!/usr/bin/env bash
# Data validation (exit 2, one ERROR line, no traceback), pipe escaping in the
# Open Questions markdown, missing openpyxl, and no bytecode left behind.
set -u
. "$(dirname "$0")/lib.sh"
BUILD="$CK/build_checklist.py"
DIFF="$CK/diff_user_edits.py"
T=$(tmpdir); trap 'rm -rf "$T"' EXIT

BASE='PROJECT = dict(name="ShopLite", prefix="SHP", project="p", version="1", sources="s", test_site="t")
ACCOUNTS = []
REQS = [("US-1", "r", "E1", "§1", "ok")]
TCS = [("US-1", "E1", "f", "s", "a|b", "e", "Functional", "High")]
'

# bad <label> <expected-substring> <extra python lines...>: build must exit 2 with a named ERROR.
bad() {
  local label="$1" needle="$2"; shift 2
  { echo "$BASE"; printf '%s\n' "$@"; } > "$T/d.py"
  rm -f "$T/o.xlsx"
  local err rc
  err=$(python3 "$BUILD" "$T/d.py" "$T/o.xlsx" 2>&1 >/dev/null); rc=$?
  assert_eq 2 "$rc" "$label: exit 2"
  assert_contains "$err" "ERROR:" "$label: ERROR line"
  assert_contains "$err" "$needle" "$label: names $needle"
  case "$err" in *Traceback*) fail "$label: no traceback" ;; *) pass "$label: no traceback" ;; esac
  [ ! -e "$T/o.xlsx" ] && pass "$label: no output file" || fail "$label: no output file"
}

echo "validation: types"
bad "version number" "PROJECT.version" 'PROJECT["version"] = 6.2'
bad "bare result string" "RESULTS SHP-001" 'RESULTS = {"SHP-001": "PASS"}'
bad "short result tuple" "RESULTS SHP-001" 'RESULTS = {"SHP-001": ("PASS",)}'
bad "non-string result" "RESULTS SHP-001" 'RESULTS = {"SHP-001": ("PASS", 5, "")}'
bad "oq tcs string" "tcs must be a list" 'OQ = {"Q-1": dict(topic="t", question="q", kind="Gap", priority="P1", tcs="SHP-001")}'
bad "reqs row is a string" "REQS[2]" 'REQS.append("not a row")'
bad "tcs row is a string" "SHP-002" 'TCS.append("not a row")'
bad "issues row is a number" "ISSUES[1]" 'ISSUES = [5]'

echo "validation: illegal characters"
bad "control char in req" "REQS[1][2]" 'REQS[0] = ("US-1", "bad\x01text", "E1", "§1", "ok")'
bad "control char in project" "PROJECT['name']" 'PROJECT["name"] = "Shop\x0bLite"'
bad "control char in result" "RESULTS['SHP-001'][3]" 'RESULTS = {"SHP-001": ("PASS", "Linh", "x\x02y")}'

echo "oq: pipes escaped in table cells"
{ echo "$BASE"; cat <<'PY'
PROJECT["sources"] = "a|b"
PROJECT["project"] = "mod|ule"
OQ = {"Q-1": dict(topic="Cart | checkout", question="q", kind="Gap", priority="P1", tcs=["SHP-001"])}
PY
} > "$T/p.py"
python3 "$BUILD" "$T/p.py" "$T/p.xlsx" "$T/p.md" >/dev/null 2>&1; assert_eq 0 "$?" "pipes: builds"
md=$(cat "$T/p.md")
assert_contains "$md" '| Q-1 | Cart \| checkout | Gap | P1 | SHP-001 | OPEN |' "topic pipe escaped in summary row"
assert_contains "$md" '| **Tài liệu nguồn** | a\|b |' "sources pipe escaped"
assert_contains "$md" '| **Module** | mod\|ule |' "module pipe escaped"
assert_contains "$md" '### Q-1 — Cart | checkout' "heading keeps the raw pipe"

echo "cli: missing openpyxl"
for cli in "$BUILD:$T/d.py $T/x.xlsx" "$DIFF:$T/x.xlsx $T/d.py"; do
  script="${cli%%:*}"; args="${cli#*:}"
  err=$(python3 -c "
import sys, runpy
sys.modules['openpyxl'] = None
sys.argv = [sys.argv[1]] + sys.argv[2:]
runpy.run_path(sys.argv[0], run_name='__main__')" "$script" $args 2>&1 >/dev/null); rc=$?
  assert_eq 2 "$rc" "$(basename "$script"): exit 2 without openpyxl"
  assert_eq "ERROR: openpyxl is required: python3 -m pip install openpyxl (or use a venv)" "$err" "$(basename "$script"): one-line message"
done

echo "cli: no bytecode"
D=$(tmpdir)
cp -r "$CK" "$D/ck"
python3 "$D/ck/build_checklist.py" "$PLUGIN/templates/checklist/example_data.py" "$D/o.xlsx" >/dev/null 2>&1
python3 "$D/ck/diff_user_edits.py" "$D/o.xlsx" "$PLUGIN/templates/checklist/example_data.py" >/dev/null 2>&1
find "$D/ck" -name '__pycache__' -o -name '*.pyc' | grep -q . && fail "bytecode written next to scripts" || pass "no bytecode written next to scripts"
rm -rf "$D"

exit $FAILS
