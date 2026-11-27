#!/usr/bin/env bash
# Checks the six yn-qc skills: names, frontmatter, side-effect flags,
# cross references, and that no project-specific data ships in the plugin.
cd "$(dirname "$0")/../.." || exit 1
. tests/qc/lib.sh

SKILLS="requirement-review checklist-gen checklist-import ticket-review retest-run testrun-report"
WRITERS=" checklist-gen checklist-import retest-run "

fm_get() { # <file> <key>
  awk -v k="$2" '
    NR == 1 { if ($0 != "---") exit; next }
    $0 == "---" { exit }
    { i = index($0, ":"); if (i > 0 && substr($0, 1, i - 1) == k) {
        v = substr($0, i + 1); sub(/^[ \t]+/, "", v); sub(/[ \t\r]+$/, "", v); print v; exit } }
  ' "$1"
}

for s in $SKILLS; do
  f="$PLUGIN/skills/$s/SKILL.md"
  if [ ! -f "$f" ]; then fail "$s: SKILL.md exists"; continue; fi
  pass "$s: SKILL.md exists"
  assert_eq "$s" "$(fm_get "$f" name)" "$s: frontmatter name"
  d=$(fm_get "$f" description)
  [ -n "$d" ] && pass "$s: has description" || fail "$s: has description"
  case "$d" in *". "*) fail "$s: description is one sentence" ;; *) pass "$s: description is one sentence" ;; esac
  [ "${#d}" -le 300 ] && pass "$s: description <= 300 chars" || fail "$s: description <= 300 chars (${#d})"
  dmi=$(fm_get "$f" disable-model-invocation)
  case "$WRITERS" in
    *" $s "*) assert_eq "true" "$dmi" "$s: disable-model-invocation true (writes files)" ;;
    *) assert_eq "" "$dmi" "$s: no disable-model-invocation" ;;
  esac
  fb=$(grep -F 'If `${CLAUDE_SKILL_DIR}` is not set' "$f")
  case "$WRITERS" in
    *" $s "*)
      if [ "$s" = retest-run ]; then
        assert_eq "" "$fb" "$s: no fallback line (its zip bundles no folders)"
        assert_contains "$(cat "$f")" "checklist-gen skill" "$s: declares the checklist-gen dependency"
        continue
      fi
      assert_contains "$fb" "two levels above" "$s: fallback names the plugin layout"
      assert_contains "$fb" "next to this file" "$s: fallback names the zip layout" ;;
    *) assert_eq "" "$fb" "$s: no script fallback line (uses no scripts)" ;;
  esac
done

# No project data anywhere in the plugin, docs/ or the root README. Allowed: the repo coordinate and the
# plugin.json author, which name the GitHub org that hosts the marketplace.
RE='metafox|donation|live video|advanced marketplace|younet|apps\.metafox|drive\.google|qc-lead-copilot|qc-manual-copilot|qc-built-checklist|qc-review-ticket|vong-retest|pipeline-test-tach|qc-checklist-tu-tai-lieu'
# Optional untracked file with extra patterns (one regex per line), kept out of git.
LOCAL_DENY=".yn/qc-denylist.local"
if [ -f "$LOCAL_DENY" ]; then
  extra=$(grep -v '^[[:space:]]*$' "$LOCAL_DENY" | paste -sd'|' -)
  [ -n "$extra" ] && RE="$RE|$extra"
fi
content_of() { # <file>: text to scan, with allowed tokens removed
  case "$1" in
    *.xlsx) python3 -c 'import sys, zipfile
z = zipfile.ZipFile(sys.argv[1])
for n in z.namelist(): sys.stdout.write(z.read(n).decode("utf-8", "replace") + "\n")' "$1" ;;
    */plugin.json) sed -e 's#metafoxapp/claude-tools##g' -e '/^ *"name": "metafoxapp"$/d' "$1" ;;
    *) sed -e 's#metafoxapp/claude-tools##g' "$1" ;;
  esac
}
hits=""
while IFS= read -r f; do
  h=$(content_of "$f" | grep -aniE "$RE" | head -3)
  [ -n "$h" ] && hits="$hits
$f: $h"
done < <({ find "$PLUGIN" docs -type f -not -path '*/__pycache__/*' -not -name '*.pyc'; echo README.md; } | sort)
if [ -z "$hits" ]; then pass "no project data in plugins/yn-qc, docs/, README.md"; else fail "no project data in plugins/yn-qc, docs/, README.md:$hits"; fi

# Every /yn-qc:<skill> reference points to a real skill.
bad=""
for ref in $(grep -rhoE '/yn-qc:[a-z0-9-]+' "$PLUGIN" --exclude-dir=__pycache__ | sort -u); do
  [ -f "$PLUGIN/skills/${ref#/yn-qc:}/SKILL.md" ] || bad="$bad $ref"
done
assert_eq "" "$bad" "all /yn-qc:<skill> references resolve"

# checklist-gen calls the plugin scripts instead of embedding them.
cg="$PLUGIN/skills/checklist-gen/SKILL.md"
if [ -f "$cg" ]; then
  assert_eq "0" "$(grep -c '^from openpyxl' "$cg")" "checklist-gen embeds no Python"
  for w in build_checklist.py diff_user_edits.py checklist-guide.md; do
    assert_contains "$(cat "$cg")" "$w" "checklist-gen mentions $w"
  done
else
  fail "checklist-gen present for content checks"
fi

# requirement-review: trigger-style description and output that feeds checklist-gen.
rr="$PLUGIN/skills/requirement-review/SKILL.md"
if [ -f "$rr" ]; then
  case "$(fm_get "$rr" description)" in "Use when"*) pass "requirement-review: description starts with Use when" ;;
    *) fail "requirement-review: description starts with Use when" ;; esac
  assert_contains "$(cat "$rr")" "| Req ID | Epic | Feature | Scenario | Steps | Expected | Type | Priority |" "requirement-review: scenario table matches checklist-gen TCS"
  assert_contains "$(cat "$rr")" 'kind="Conflict"' "requirement-review: Conflict maps to an OQ kind"
  assert_contains "$(cat "$rr")" 'kind="Gap"' "requirement-review: Gap maps to an OQ kind"
fi

exit $FAILS
