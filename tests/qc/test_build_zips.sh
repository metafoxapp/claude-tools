#!/usr/bin/env bash
# build-zips.sh packs each skill into a self-contained zip for claude.ai.
source "$(dirname "$0")/lib.sh"
REPO="$(cd "$PLUGIN/../.." && pwd)"
OUT="$(tmpdir)"
cp -r "$REPO/scripts" "$REPO/plugins" "$OUT/" 2>/dev/null
mkdir -p "$OUT/.claude-plugin"
cd "$OUT" && bash scripts/build-zips.sh yn-qc >/dev/null 2>&1
rc=$?
assert_eq 0 "$rc" "build-zips exits 0"
D="$OUT/dist/yn-qc"
assert_eq 7 "$(ls "$D"/*.zip 2>/dev/null | wc -l | tr -d ' ')" "7 zips"
for s in requirement-review release-review checklist-gen checklist-import ticket-review retest-run testrun-report; do
  assert_contains "$(unzip -l "$D/$s.zip" 2>/dev/null)" "$s/SKILL.md" "$s zip has SKILL.md"
  assert_eq 0 "$(unzip -p "$D/$s.zip" "$s/SKILL.md" | grep -c '\.\./\.\./')" "$s SKILL.md has no ../../"
done
L="$(unzip -l "$D/checklist-gen.zip")"
assert_contains "$L" "checklist-gen/scripts/checklist/build_checklist.py" "gen has builder"
assert_contains "$L" "checklist-gen/templates/checklist/checklist-template.xlsx" "gen has template"
assert_contains "$L" "checklist-gen/docs/checklist-guide.md" "gen has guide"
case "$L" in *__pycache__*|*.pyc*) fail "gen zip contains bytecode" ;; *) pass "no bytecode" ;; esac
assert_eq 1 "$(unzip -l "$D/ticket-review.zip" | grep -c 'ticket-review/.*[^/]$')" "ticket-review only SKILL.md"
X="$(tmpdir)"; unzip -q "$D/checklist-gen.zip" -d "$X"
python3 "$X/checklist-gen/scripts/checklist/build_checklist.py" \
  "$X/checklist-gen/templates/checklist/example_data.py" "$X/out.xlsx" >/dev/null 2>&1
assert_eq 0 "$?" "builder from zip runs"
for s in requirement-review release-review checklist-gen checklist-import ticket-review retest-run testrun-report; do
  if unzip -p "$D/$s.zip" "$s/SKILL.md" | grep -q 'next to this file'; then
    assert_contains "$(unzip -l "$D/$s.zip")" "$s/scripts/" "$s: 'next to this file' is true (scripts/ in zip)"
  fi
done
for s in requirement-review release-review checklist-gen checklist-import ticket-review retest-run testrun-report; do
  md="$(unzip -p "$D/$s.zip" "$s/SKILL.md")"
  keys=$(printf '%s\n' "$md" | awk 'NR == 1 { next } $0 == "---" { exit } /^[A-Za-z][A-Za-z0-9_-]*:/ { sub(/:.*/, ""); print }' | sort -u)
  badkeys=$(printf '%s\n' "$keys" | grep -vxE 'name|description|license|allowed-tools|metadata|compatibility')
  assert_eq "" "$badkeys" "$s zip frontmatter has only claude.ai keys"
  assert_eq 0 "$(printf '%s\n' "$md" | grep -c '/yn-qc:')" "$s zip SKILL.md has no /yn-qc: references"
done
assert_contains "$(unzip -p "$D/checklist-import.zip" checklist-import/SKILL.md)" "the checklist-gen skill" "sibling reference rewritten in words"
rm -rf "$OUT" "$X"
[ "$FAILS" -eq 0 ]
