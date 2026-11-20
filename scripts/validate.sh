#!/usr/bin/env bash
# Validates repository conventions (see docs/CONVENTIONS.md). Exit 1 on any error.
# Requires: jq.
set -uo pipefail
cd "$(dirname "$0")/.."

ROLES="core|dev|qc|pm|design|ops"
VERBS="init|add|triage|run|status|list|review|gen|fix|report|import"
errors=0
err() { echo "ERROR: $*" >&2; errors=$((errors + 1)); }

command -v jq >/dev/null 2>&1 || { echo "jq is required" >&2; exit 2; }

mp=".claude-plugin/marketplace.json"
[ -f "$mp" ] || { echo "missing $mp" >&2; exit 1; }
jq empty "$mp" 2>/dev/null || { echo "$mp is not valid JSON" >&2; exit 1; }
[ "$(jq -r .name "$mp")" = "yn-tools" ] || err "$mp: name must be 'yn-tools'"

fm_get() { # <file> <key>
  awk -v k="$2" '
    NR == 1 { if ($0 != "---") exit; next }
    $0 == "---" { exit }
    { i = index($0, ":"); if (i > 0 && substr($0, 1, i - 1) == k) {
        v = substr($0, i + 1); sub(/^[ \t]+/, "", v); sub(/[ \t\r]+$/, "", v); print v; exit } }
  ' "$1"
}

listed=""
for name in $(jq -r '.plugins[].name' "$mp"); do
  listed="$listed $name"
  echo "$name" | grep -Eq "^yn-($ROLES)$" || err "plugin '$name': must match ^yn-($ROLES)\$"
  src=$(jq -r --arg n "$name" '.plugins[] | select(.name==$n) | .source' "$mp")
  dir="${src#./}"
  [ -d "$dir" ] || { err "plugin '$name': source dir '$dir' not found"; continue; }
  [ "$dir" = "plugins/$name" ] || err "plugin '$name': source must be ./plugins/$name (got $src)"

  pj="$dir/.claude-plugin/plugin.json"
  if [ ! -f "$pj" ]; then err "$name: missing $pj"; else
    jq empty "$pj" 2>/dev/null || err "$pj is not valid JSON"
    [ "$(jq -r .name "$pj")" = "$name" ] || err "$pj: name must be '$name'"
    mv_=$(jq -r --arg n "$name" '.plugins[] | select(.name==$n) | .version' "$mp")
    pv=$(jq -r .version "$pj")
    echo "$pv" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || err "$pj: version '$pv' is not semver"
    [ "$mv_" = "$pv" ] || err "$name: version mismatch (marketplace $mv_ vs plugin.json $pv)"
  fi
  [ -f "$dir/README.md" ] || err "$name: missing README.md"
  [ -f "$dir/CHANGELOG.md" ] || err "$name: missing CHANGELOG.md"

  for sd in "$dir"/skills/*/; do
    [ -d "$sd" ] || continue
    s=$(basename "$sd")
    [ -f "$sd/SKILL.md" ] || { err "$name/$s: missing SKILL.md"; continue; }
    echo "$s" | grep -Eq "^[a-z0-9]+(-[a-z0-9]+)*-($VERBS)$" || err "$name/$s: skill dir must be <tool>-<verb> with verb in ($VERBS)"
    [ "$(fm_get "$sd/SKILL.md" name)" = "$s" ] || err "$name/$s: frontmatter name must equal directory name"
    [ -n "$(fm_get "$sd/SKILL.md" description)" ] || err "$name/$s: missing description"
  done

  for af in "$dir"/agents/*.md; do
    [ -e "$af" ] || continue
    a=$(basename "$af" .md)
    [ "$(fm_get "$af" name)" = "$a" ] || err "$name/agents/$a: frontmatter name must equal file name"
    [ -n "$(fm_get "$af" description)" ] || err "$name/agents/$a: missing description"
  done

  if [ -f "$dir/hooks/hooks.json" ]; then jq empty "$dir/hooks/hooks.json" 2>/dev/null || err "$name: hooks/hooks.json invalid JSON"; fi

  for sh in $(find "$dir" -name '*.sh'); do
    bash -n "$sh" 2>/dev/null || err "$sh: bash syntax error"
    [ -x "$sh" ] || err "$sh: not executable (chmod +x)"
  done
done

for pdir in plugins/*/; do
  p=$(basename "$pdir")
  case " $listed " in *" $p "*) ;; *) err "plugins/$p is not listed in $mp" ;; esac
done

if [ "$errors" -gt 0 ]; then echo "validate: $errors error(s)" >&2; exit 1; fi
echo "validate: OK"
