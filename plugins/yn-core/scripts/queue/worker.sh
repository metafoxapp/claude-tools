#!/usr/bin/env bash
# Usage: worker.sh <group> [--max-tasks N] [--dry-run]
# Headless worker for one group. Runs tasks sequentially in a dedicated git
# worktree (.claude/worktrees/q-<group>, branch yn-queue/<group>):
#   claim -> `claude -p` implements -> THIS SCRIPT re-runs the verify command
#   independently -> review/ on success, ready/ (retry) or failed/ otherwise.
# It never pushes and never merges.
# Env: YN_CLAUDE_BIN (default: claude), YN_QUEUE_DIR.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/common.sh"
yn_require_queue

group="${1:?usage: worker.sh <group> [--max-tasks N] [--dry-run]}"
shift
max_tasks=5
dry=0
while [ $# -gt 0 ]; do
  case "$1" in
    --max-tasks) max_tasks="${2:?--max-tasks needs a number}"; shift 2 ;;
    --dry-run) dry=1; shift ;;
    *) yn_die "unknown argument: $1" ;;
  esac
done

root=$(yn_repo_root)
base=$(cfg_top base_branch); base=${base:-main}
max_turns=$(cfg_top max_turns); max_turns=${max_turns:-40}
budget=$(cfg_top max_budget_usd); budget=${budget:-5}
max_attempts=$(cfg_top max_attempts); max_attempts=${max_attempts:-2}
group_verify=$(cfg_group "$group" verify)
claude_bin="${YN_CLAUDE_BIN:-claude}"

wt="$root/.claude/worktrees/q-$group"
branch="yn-queue/$group"

if [ "$dry" = 1 ]; then
  next=$(YN_PEEK=1 "$here/claim.sh" "$group" || true)
  if [ -n "$next" ]; then echo "[dry-run] next task: $(basename "$next" .md) (worktree $wt, branch $branch)"; else echo "[dry-run] no eligible task in '$group'"; fi
  exit 0
fi

# One worker per group at a time.
lock="$YN_QUEUE_DIR/.worker-$group.lock"
mkdir "$lock" 2>/dev/null || yn_die "a worker for '$group' is already running (remove $lock if stale)"
trap 'rmdir "$lock" 2>/dev/null || true' EXIT

if [ ! -d "$wt" ]; then
  git -C "$root" worktree add -B "$branch" "$wt" "$base" >/dev/null
fi

processed=0
while [ "$processed" -lt "$max_tasks" ]; do
  f=$("$here/claim.sh" "$group") || break
  id=$(basename "$f" .md)
  verify=$(fm_get "$f" verify); verify=${verify:-$group_verify}
  stamp=$(date +%Y%m%d-%H%M%S)
  log="$YN_QUEUE_DIR/log/$id-$stamp"

  if [ -z "$verify" ]; then
    {
      echo; echo "## Failure"
      echo "No verify command: set groups.$group.verify in $YN_QUEUE_DIR/config.yaml or 'verify:' on the task."
    } >> "$f"
    "$here/move.sh" "$id" failed >/dev/null
    echo "$id: failed (no verify command)"
    processed=$((processed + 1))
    continue
  fi

  attempts_file="$YN_QUEUE_DIR/log/$id.attempts"
  attempt=$(( $(cat "$attempts_file" 2>/dev/null || echo 0) + 1 ))
  echo "$attempt" > "$attempts_file"
  start_sha=$(git -C "$wt" rev-parse HEAD)

  allowed="Read,Edit,Write,Glob,Grep,Bash(git status*),Bash(git diff*),Bash(git add *),Bash(git commit *),Bash(git log *),Bash($verify),Bash($verify *)"
  extra=$(cfg_group "$group" allowed_tools)
  [ -z "$extra" ] || allowed="$allowed,$extra"

  prompt="You are a queue worker (yn-core). Implement exactly ONE task, then stop.

Rules:
- Work only inside this worktree (cwd), branch $branch.
- Stay within the task's 'touches' scope; if you must go outside, say why in your final message.
- Add or update tests for each acceptance criterion when the project has tests.
- Run the verify command and make it pass: $verify
- Commit once with the message '$id: <short title>'. Do NOT push, merge, or touch anything under .yn/.
- If you are blocked, explain why in your final message and stop WITHOUT committing.

----- TASK $id -----
$(cat "$f")"

  rc=0
  (cd "$wt" && "$claude_bin" -p "$prompt" \
      --permission-mode dontAsk \
      --allowedTools "$allowed" \
      --disallowedTools "Bash(git push*),Bash(rm -rf*)" \
      --max-turns "$max_turns" --max-budget-usd "$budget" \
      --output-format json) > "$log.json" 2> "$log.err" || rc=$?

  # Independent verification: never trust the worker's own claim of success.
  vrc=0
  (cd "$wt" && bash -c "$verify") > "$log.verify.txt" 2>&1 || vrc=$?
  commits=$(git -C "$wt" log "$start_sha..HEAD" --oneline | wc -l | tr -d ' ')

  if [ "$rc" -eq 0 ] && [ "$vrc" -eq 0 ] && [ "$commits" -ge 1 ]; then
    {
      echo; echo "## Evidence ($(date '+%Y-%m-%d %H:%M'), attempt $attempt, branch $branch)"
      echo '```'; tail -n 40 "$log.verify.txt"; echo '```'
      echo "Commits: $(git -C "$wt" log "$start_sha..HEAD" --format='%h %s' | tr '\n' ';')"
    } >> "$f"
    "$here/move.sh" "$id" review >/dev/null
    echo "$id: review"
  else
    # Discard partial work of this attempt (dedicated queue worktree only).
    git -C "$wt" reset --hard "$start_sha" >/dev/null 2>&1 || true
    git -C "$wt" clean -fdq >/dev/null 2>&1 || true
    reason="claude rc=$rc, verify rc=$vrc, commits=$commits"
    if [ "$attempt" -ge "$max_attempts" ]; then
      {
        echo; echo "## Failure (attempt $attempt)"; echo "$reason"
        echo "Logs: $log.json, $log.err, $log.verify.txt"
      } >> "$f"
      "$here/move.sh" "$id" failed >/dev/null
      echo "$id: failed ($reason)"
    else
      "$here/move.sh" "$id" ready >/dev/null
      echo "$id: retry later ($reason)"
    fi
  fi
  processed=$((processed + 1))
done

echo "worker[$group]: processed $processed task(s); branch $branch"
