#!/usr/bin/env bash
# Usage: init.sh [--preset NAME]
# Creates .yn/queue/ in the current repository (idempotent), writes config.yaml
# from a preset if missing, updates .gitignore, and copies the worker scripts to
# .yn/queue/bin/ so cron/launchd never points into the versioned plugin cache.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/common.sh"
plugin_root="$(cd "$here/../.." && pwd)"

preset=""
while [ $# -gt 0 ]; do
  case "$1" in
    --preset) preset="${2:?--preset needs a name}"; shift 2 ;;
    *) yn_die "unknown argument: $1" ;;
  esac
done
[ -n "$preset" ] || preset=$("$here/detect-stack.sh")
src="$plugin_root/presets/queue/$preset.yaml"
[ -f "$src" ] || yn_die "unknown preset '$preset' (see $plugin_root/presets/queue/)"

for d in $YN_STATES log bin; do mkdir -p "$YN_QUEUE_DIR/$d"; done

if [ -f "$YN_QUEUE_DIR/config.yaml" ]; then
  echo "config.yaml: kept existing"
else
  cp "$src" "$YN_QUEUE_DIR/config.yaml"
  echo "config.yaml: created from preset '$preset'"
fi

for f in common.sh claim.sh move.sh add.sh status.sh autorun.sh worker.sh; do
  cp "$here/$f" "$YN_QUEUE_DIR/bin/$f"
  chmod +x "$YN_QUEUE_DIR/bin/$f"
done
echo "bin/: worker scripts copied to $YN_QUEUE_DIR/bin (re-run init to refresh after plugin updates)"

root=$(yn_repo_root)
gi="$root/.gitignore"
touch "$gi"
for pat in ".yn/queue/*" "!.yn/queue/config.yaml" ".claude/worktrees/"; do
  grep -qxF -- "$pat" "$gi" || echo "$pat" >> "$gi"
done
echo ".gitignore: queue state ignored, .yn/queue/config.yaml stays shareable"

cat <<'EOF'

Recommended permissions for .claude/settings.json (review before merging):
{
  "permissions": {
    "deny": [
      "Bash(git push --force*)",
      "Bash(git push origin main*)",
      "Bash(rm -rf*)",
      "Read(./.env)",
      "Read(./secrets/**)"
    ]
  }
}
EOF
