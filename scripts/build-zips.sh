#!/usr/bin/env bash
# Packs each skill of a plugin into dist/<plugin>/<skill>.zip for upload to claude.ai.
# Usage: bash scripts/build-zips.sh [plugin=yn-qc]
# Each zip has a root folder <skill>/ with SKILL.md, plus scripts/, templates/ and docs/
# when the SKILL.md references them via ../../. Writes only under dist/.
set -euo pipefail
command -v zip >/dev/null || { echo "zip not found" >&2; exit 1; }
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN_NAME="${1:-yn-qc}"
PDIR="$ROOT/plugins/$PLUGIN_NAME"
[ -d "$PDIR/skills" ] || { echo "no skills in $PDIR" >&2; exit 1; }
DIST="$ROOT/dist/$PLUGIN_NAME"
rm -rf "$DIST"; mkdir -p "$DIST"
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/build-zips.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT

for sdir in "$PDIR"/skills/*/; do
  skill="$(basename "$sdir")"
  [ -f "$sdir/SKILL.md" ] || continue
  dest="$STAGE/$skill"; mkdir -p "$dest"
  for sub in scripts templates docs; do
    if grep -q "\.\./\.\./$sub/" "$sdir/SKILL.md"; then
      cp -r "$PDIR/$sub" "$dest/$sub"
    fi
  done
  find "$dest" \( -name __pycache__ -o -name '*.pyc' \) -prune -exec rm -rf {} + 2>/dev/null || true
  # claude.ai accepts only name, description, license, allowed-tools, metadata and
  # compatibility in the frontmatter, and has no /plugin:skill commands: strip the
  # Claude Code-only keys and name sibling skills in words.
  sed -e 's#\${CLAUDE_SKILL_DIR}/\.\./\.\./#${CLAUDE_SKILL_DIR}/#g' \
      -e 's#\.\./\.\./\(scripts\|templates\|docs\)/#\1/#g' \
      -e "s#\`/$PLUGIN_NAME:\([a-z0-9-]*\)\`#the \1 skill#g" \
      -e "s#/$PLUGIN_NAME:\([a-z0-9-]*\)#the \1 skill#g" "$sdir/SKILL.md" |
    awk 'NR == 1 && $0 == "---" { fm = 1; print; next }
         fm && $0 == "---" { fm = 0 }
         fm && /^(argument-hint|disable-model-invocation):/ { next }
         { print }' > "$dest/SKILL.md"
  (cd "$STAGE" && zip -qr "$DIST/$skill.zip" "$skill")
  echo "dist/$PLUGIN_NAME/$skill.zip"
done
