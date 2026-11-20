#!/usr/bin/env bash
# Shared helpers for yn-core queue scripts. Source this file; do not execute it.
# Compatible with bash 3.2 (macOS default): no associative arrays, no mapfile.

# Root of the MAIN checkout, even when called from a linked worktree, so every
# worktree sees the same queue.
yn_repo_root() {
  local common
  if common=$(git rev-parse --git-common-dir 2>/dev/null); then
    (cd "$common/.." 2>/dev/null && pwd -P) || pwd -P
  else
    pwd -P
  fi
}

: "${YN_QUEUE_DIR:=$(yn_repo_root)/.yn/queue}"
export YN_QUEUE_DIR
YN_STATES="inbox ready doing review failed done"

yn_die() { echo "yn-queue: $*" >&2; exit 1; }

yn_require_queue() {
  [ -d "$YN_QUEUE_DIR/ready" ] || yn_die "queue not initialised at $YN_QUEUE_DIR (run /yn-core:queue-init)"
}

# fm_get <file> <key>: value of a front-matter key (first match), trimmed.
fm_get() {
  awk -v k="$2" '
    NR == 1 { if ($0 != "---") exit; next }
    $0 == "---" { exit }
    { i = index($0, ":")
      if (i > 0 && substr($0, 1, i - 1) == k) {
        v = substr($0, i + 1); sub(/^[ \t]+/, "", v); sub(/[ \t\r]+$/, "", v); print v; exit
      } }
  ' "$1"
}

# fm_list <file> <key>: items of an inline list "[a, b]", one per line.
fm_list() {
  fm_get "$1" "$2" | tr -d '[]' | tr ',' '\n' | sed 's/^[ \t]*//;s/[ \t]*$//' | sed '/^$/d'
}

# task_file <id>: path of the task in whichever state it currently is.
task_file() {
  local s
  for s in $YN_STATES; do
    if [ -f "$YN_QUEUE_DIR/$s/$1.md" ]; then echo "$YN_QUEUE_DIR/$s/$1.md"; return 0; fi
  done
  return 1
}

# cfg_top <key>: top-level scalar from config.yaml.
cfg_top() {
  [ -f "$YN_QUEUE_DIR/config.yaml" ] || return 0
  awk -v k="$1" '
    index($0, k ":") == 1 {
      v = substr($0, length(k) + 2); sub(/^[ \t]+/, "", v); sub(/[ \t]+#.*$/, "", v)
      sub(/[ \t\r]+$/, "", v); print v; exit
    }' "$YN_QUEUE_DIR/config.yaml"
}

# cfg_group <group> <key>: scalar under groups.<group> in config.yaml.
cfg_group() {
  [ -f "$YN_QUEUE_DIR/config.yaml" ] || return 0
  awk -v g="$1" -v k="$2" '
    /^groups:/ { ing = 1; next }
    ing && /^[^ #]/ { ing = 0 }
    ing && /^  [A-Za-z0-9_-]+:[ \t]*$/ { cur = $1; sub(/:$/, "", cur); next }
    ing && cur == g && index($0, "    " k ":") == 1 {
      v = substr($0, length(k) + 6); sub(/^[ \t]+/, "", v); sub(/[ \t]+#.*$/, "", v)
      sub(/[ \t\r]+$/, "", v); sub(/^"/, "", v); sub(/"$/, "", v); print v; exit
    }' "$YN_QUEUE_DIR/config.yaml"
}

# cfg_groups: names of all groups in config.yaml.
cfg_groups() {
  [ -f "$YN_QUEUE_DIR/config.yaml" ] || return 0
  awk '
    /^groups:/ { ing = 1; next }
    ing && /^[^ #]/ { ing = 0 }
    ing && /^  [A-Za-z0-9_-]+:[ \t]*$/ { g = $1; sub(/:$/, "", g); print g }
  ' "$YN_QUEUE_DIR/config.yaml"
}
