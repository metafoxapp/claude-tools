---
name: queue-triage
description: Classify queued inbox tasks into groups and make them ready to run. Use after adding tasks to the YN queue.
allowed-tools: Bash(bash *scripts/queue/*) Read Edit
---
Triage every task in `.yn/queue/inbox/`.

1. Read `.yn/queue/config.yaml` (groups, `paths`, `verify`) and each inbox task file.
2. A task is ready only if it has a title, at least one acceptance line, and a verify command (its own `verify:` or the group's). Otherwise leave it in `inbox/`, append a `## Needs` section with the exact missing item, and list it in your report.
3. Assign `group` by matching the task's `touches` against group `paths`. Edit the front matter in place.
4. A task touching two groups must be split: create one task per group with `add.sh` (see queue-add), link them with `depends_on`, and move the original to `done/` with a note, or rewrite it as one of the parts. Tasks in the same group that touch the same files must stay in that group so they run sequentially.
5. Set `priority` (1 urgent … 5 low) and `depends_on` where order matters. Do not invent dependencies.
6. Move each triaged task: `bash "${CLAUDE_SKILL_DIR}/../../scripts/queue/move.sh" <id> ready`.
7. Report a table: id, title, group, priority, depends_on, and the tasks left in the inbox with the reason. Then show `bash "${CLAUDE_SKILL_DIR}/../../scripts/queue/status.sh"`.
