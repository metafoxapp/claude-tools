---
name: queue-run
description: Implement ready tasks from the YN queue, by group, in parallel worktrees, or in autorun mode.
argument-hint: "<group> | all | --autorun [N] | stop"
disable-model-invocation: true
allowed-tools: Bash(bash *scripts/queue/*) Bash(git *)
---
Scripts live in `${CLAUDE_SKILL_DIR}/../../scripts/queue/` (call it `$Q` below). Arguments: $ARGUMENTS

## `stop`
Run `bash $Q/autorun.sh off` and report.

## `--autorun [N]`
Run `bash $Q/autorun.sh on N` (default 20). Then process one group as below. The Stop hook will keep you going while ready tasks remain and progress is being made. Tell the user `/yn-core:queue-run stop` cancels it.

## `<group>` (in this session)
Repeat until `claim.sh` exits 3 (nothing eligible):
1. Safety: if the current branch is the project's base branch or `main`/`master`, create and switch to `yn-queue/<group>` first. Never commit to the base branch.
2. `f=$(bash $Q/claim.sh <group>)` — this moves the task to `doing/`. Read it fully.
3. Implement only what the acceptance criteria ask, staying within `touches`. Add/update tests for each criterion when the project has tests.
4. Run the task's `verify:` (or the group's `verify` in `.yn/queue/config.yaml`). It must pass. Paste the last ~40 lines under a `## Evidence` heading in the task file. If there is no verify command, move the task to `failed` explaining that.
5. Commit once: `<id>: <title>`. Do not push or merge.
6. `bash $Q/move.sh <id> review`.
7. If blocked or verify cannot pass after two honest attempts: write `## Failure` with the reason, `move.sh <id> failed`, continue with the next task.
Finish with `bash $Q/status.sh` and a short list of what moved to review/failed.

## `all` (parallel)
1. Run `bash $Q/status.sh`; collect groups that have ready tasks.
2. Spawn one `yn-core:queue-worker` subagent per such group, in parallel and in the background, each with the prompt: "Group: <group>. Queue scripts: <absolute path of $Q>. Process every eligible task of this group."
3. When they finish, summarise per group: tasks moved to review/failed and the branch each subagent reported. Remind the user that nothing is merged: review each group's branch before merging.

Never modify files under `.yn/queue/` other than task files, and never push.
