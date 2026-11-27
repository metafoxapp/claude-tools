#!/usr/bin/env bash
# build_checklist.py: workbook layout, formulas, validation, Open Questions markdown.
set -u
. "$(dirname "$0")/lib.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"
BUILD="$CK/build_checklist.py"
INSPECT="$HERE/inspect_xlsx.py"
FIX="$HERE/fixtures"
T=$(tmpdir); trap 'rm -rf "$T"' EXIT

echo "build: sample data"
out=$(python3 "$BUILD" "$FIX/sample_data.py" "$T/c.xlsx" "$T/oq.md" 2>&1); rc=$?
assert_eq "0" "$rc" "exit 0"
assert_contains "$out" "Status {" "prints status counts"
assert_contains "$out" "Reqs without TC: US-9.9" "prints reqs without TC"
[ -f "$T/c.xlsx" ] && pass "xlsx created" || fail "xlsx created"
[ -f "$T/oq.md" ] && pass "oq md created" || fail "oq md created"

J=$(python3 "$INSPECT" "$T/c.xlsx" "Checklist!A3" "Checklist!F3" "Checklist!J3" "Checklist!J8" "Checklist!J2" "Checklist!K3" "Checklist!A1" \
  "RTM!F3" "RTM!N3" "RTM!G3" "Summary!A21" "Overview!A1" "Overview!B8" "Overview!A1" "Checklist!C3" "Checklist!B1")
q() { echo "$J" | jq -r "$1"; }

assert_eq '["Overview","Account testing","Checklist","RTM","Summary","Issue Log"]' "$(q '.sheets' | jq -c .)" "sheet order"
assert_eq "TC ID, Req ID, Epic, Feature, Test Scenario, Test Steps, Expected Result, Type, Priority, Status, Tester, Notes / Ticket" "$(q '.headers.Checklist|join(", ")')" "Checklist header"
assert_eq "Role, Email, Name, Status, Password, Scope / Grant, Notes" "$(q '.headers["Account testing"]|join(", ")')" "Account header"
assert_eq "Req ID, Requirement (User Story / NFR), Epic, PRD Reference, Doc Status, Linked Test Cases, # TC, # PASS, # FAIL, # KNOWN GAP, # N/A, # NOT TESTED / BLOCKED, Coverage, Requirement Result" "$(q '.headers.RTM|join(", ")')" "RTM header"
assert_eq "#, Ticket ID / Ref, Title, Type, Severity, Req ID, TC ID, Status, Jira Key, Found In, Notes" "$(q '.headers["Issue Log"]|join(", ")')" "Issue Log header"

echo "build: validations / styles"
assert_eq "PASS,FAIL,KNOWN GAP,BLOCKED,N/A,NOT TESTED" "$(q '.dv.Checklist|to_entries[]|select(.key|startswith("J"))|.value|join(",")')" "DV status list"
assert_eq "Critical,High,Medium,Low" "$(q '.dv.Checklist|to_entries[]|select(.key|startswith("I"))|.value|join(",")')" "DV priority list"
assert_eq "Pass,Fail,Open for coding,N/A" "$(q '.dv["Issue Log"]|to_entries[]|select(.key|startswith("H"))|.value|join(",")')" "DV issue status"
assert_eq "A3" "$(q '.freeze.Checklist')" "Checklist freeze A3"
assert_eq "A2:L622" "$(q '.autofilter.Checklist')" "Checklist autofilter"
assert_eq "FFFF00" "$(q '.styles["Checklist!J2"].fill')" "yellow header for Status"
assert_eq "000000" "$(q '.styles["Checklist!J2"].font_color')" "black text on yellow"
assert_eq "Arial" "$(q '.styles["Checklist!A3"].font')" "Arial font"
assert_eq "6" "$(q '.cf.Checklist|to_entries[]|select(.key|startswith("J"))|.value|length')" "6 status CF rules"

echo "build: content"
assert_eq "SHP-001" "$(q '.cells["Checklist!A3"]')" "first TC id"
assert_eq "PASS" "$(q '.cells["Checklist!J3"]')" "status from RESULTS"
assert_eq "NOT TESTED" "$(q '.cells["Checklist!J8"]')" "default status NOT TESTED"
assert_eq "Linh" "$(q '.cells["Checklist!K3"]')" "tester from RESULTS"
assert_eq $'1. Mở trang\n2. Bấm Lưu' "$(q '.cells["Checklist!F3"]')" "steps numbered, Vietnamese kept"
assert_eq "SHP-001, SHP-002" "$(q '.cells["RTM!F3"]' | head -c 16)" "RTM linked TCs joined with comma"
assert_eq '=IF(G3=0,"NO COVERAGE",IF(I3>0,"FAIL",IF(J3>0,"KNOWN GAP",IF(K3=G3,"N/A",IF(H3+K3=G3,"PASS",IF(H3>0,"PARTIAL","NOT TESTED"))))))' "$(q '.cells["RTM!N3"]')" "RTM result formula"
assert_eq "622" "$(q '.max_tc_row')" "620 TC rows"
assert_eq "true" "$(q '.formula_min_row >= 1122')" "every Checklist range formula reaches last TC row + 500"
assert_eq "1122" "$(q '.dv.Checklist|to_entries[]|select(.key|startswith("J"))|.key|split(":")[1]|ltrimstr("J")')" "DV reach equals formula reach"
assert_contains "$(q '.cells["Overview!B8"]')" "Rows after row 1122" "Overview states counted rows"
assert_eq "[]" "$(q '.numeric_divisors' | jq -c .)" "no hard-coded divisors"
assert_contains "$(q '.cells["Summary!A21"]')" "Total requirements in RTM: 13" "summary total = len(REQS)"
assert_eq "SHOPLITE — QC CHECKLIST & RTM" "$(q '.cells["Overview!A1"]')" "overview title"

echo "build: empty accounts"
cat > "$T/min.py" <<'EOF'
PROJECT = dict(name="ShopLite", prefix="SHP", project="p", version="1", sources="s", test_site="t")
ACCOUNTS = []
REQS = [("US-1", "r", "E1", "§1", "ok")]
TCS = [("US-1", "E1", "f", "s", "a|b", "e", "Functional", "High")]
EOF
python3 "$BUILD" "$T/min.py" "$T/min.xlsx" >/dev/null 2>&1; assert_eq "0" "$?" "minimal data builds"
M=$(python3 "$INSPECT" "$T/min.xlsx")
assert_eq "2" "$(echo "$M" | jq '.dimensions["Account testing"].max_row')" "account sheet: title + header only"
assert_eq "A2:L3" "$(echo "$M" | jq -r '.autofilter.Checklist')" "autofilter follows data (1 TC)"
[ ! -e "$T/min_oq.md" ] && pass "no oq file without third arg" || fail "unexpected oq file"

echo "build: bad data"
err=$(python3 "$BUILD" "$FIX/bad_data.py" "$T/bad.xlsx" 2>&1 >/dev/null); rc=$?
assert_eq "2" "$rc" "exit 2 on bad data"
assert_eq "4" "$(echo "$err" | grep -c '^ERROR:')" "four ERROR lines"
assert_contains "$err" "X-9" "unknown req reported"
assert_contains "$err" "SHP-999" "unknown RESULTS tc reported"
assert_contains "$err" "Passed" "bad status reported"
assert_contains "$err" "P0" "bad priority reported"
[ ! -e "$T/bad.xlsx" ] && pass "no output file on error" || fail "output file created on error"

echo "build: open questions markdown"
md=$(cat "$T/oq.md")
assert_contains "$md" "| ID | Chủ đề | Loại | Ưu tiên | TC đang chờ | Trạng thái |" "summary table header"
assert_contains "$md" "### Q-SHP-01 — Guest checkout allowed · **P0**" "P0 heading bold"
assert_contains "$md" "### Q-SHP-02 — Stock limit message · P1" "P1 heading plain"
assert_contains "$md" "- **Trả lời PM:**" "answer line"
assert_contains "$md" "- **A (PRD §4):** Guests can check out." "option line"
assert_contains "$md" "- **Thực tế site test:**" "site line"
assert_contains "$md" "- **Docs note:**" "docs note line"
a=$(grep -n '^## A. Mâu thuẫn giữa các tài liệu' "$T/oq.md" | cut -d: -f1)
b=$(grep -n '^## B. Thiếu hoặc chưa rõ' "$T/oq.md" | cut -d: -f1)
c1=$(grep -n '^### Q-SHP-01' "$T/oq.md" | cut -d: -f1)
c2=$(grep -n '^### Q-SHP-02' "$T/oq.md" | cut -d: -f1)
[ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$c1" ] && [ "$c1" -lt "$b" ] && [ "$b" -lt "$c2" ] && pass "Conflict under A, Gap under B" || fail "section order (a=$a c1=$c1 b=$b c2=$c2)"

exit $FAILS
