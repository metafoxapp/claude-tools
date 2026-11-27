#!/usr/bin/env bash
# Templates: empty_data.py / example_data.py build cleanly; committed template and open-questions.md stay in sync.
set -u
. "$(dirname "$0")/lib.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"
BUILD="$CK/build_checklist.py"
INSPECT="$HERE/inspect_xlsx.py"
TPL="$PLUGIN/templates/checklist"
T=$(tmpdir); trap 'rm -rf "$T"' EXIT

echo "templates: files exist"
for f in empty_data.py example_data.py checklist-template.xlsx open-questions.md; do
  [ -f "$TPL/$f" ] && pass "$f exists" || fail "$f exists"
done

echo "templates: build empty_data.py"
python3 "$BUILD" "$TPL/empty_data.py" "$T/empty.xlsx" "$T/empty.md" >/dev/null 2>&1; assert_eq "0" "$?" "empty_data builds (exit 0)"

echo "templates: build example_data.py"
python3 "$BUILD" "$TPL/example_data.py" "$T/ex.xlsx" "$T/ex.md" >/dev/null 2>&1; assert_eq "0" "$?" "example_data builds (exit 0)"

echo "templates: committed template matches rebuild"
A=$(python3 "$INSPECT" "$TPL/checklist-template.xlsx" 2>/dev/null | jq -c '{sheets,headers}')
B=$(python3 "$INSPECT" "$T/empty.xlsx" 2>/dev/null | jq -c '{sheets,headers}')
[ -n "$A" ] && assert_eq "$B" "$A" "template sheets+headers match rebuild" || fail "template readable"
assert_eq "1" "$(python3 "$INSPECT" "$TPL/checklist-template.xlsx" 2>/dev/null | jq '.headers["Account testing"]|length>0' | grep -c true)" "Account testing has header"
rows=$(python3 -c "
import openpyxl,sys
ws=openpyxl.load_workbook(sys.argv[1])['Account testing']
print(sum(1 for r in ws.iter_rows(min_row=3) if any(c.value not in (None,'') for c in r)))" "$TPL/checklist-template.xlsx")
assert_eq "0" "$rows" "Account testing has only the header row"

echo "templates: open-questions.md matches rebuild from example"
if cmp -s "$TPL/open-questions.md" "$T/ex.md"; then pass "open-questions.md identical"; else fail "open-questions.md differs from rebuild"; fi

echo "templates: example content"
J=$(python3 "$INSPECT" "$T/ex.xlsx" 2>/dev/null)
assert_eq "ok" "$(python3 -c "
import sys,importlib.util
s=importlib.util.spec_from_file_location('d',sys.argv[1]);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
st={v[0] for v in m.RESULTS.values()}
ok=len(m.REQS)==3 and len(m.TCS)==5 and len(m.OQ)==2 and {'PASS','FAIL','BLOCKED'}<=st
print('ok' if ok else 'bad')" "$TPL/example_data.py")" "example: 3 req, 5 TC, 2 OQ, PASS/FAIL/BLOCKED"

exit $FAILS
