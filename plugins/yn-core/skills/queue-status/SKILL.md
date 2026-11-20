---
name: queue-status
description: Show YN task queue counts per state and per group, and whether autorun is on.
allowed-tools: Bash(bash *scripts/queue/status.sh*)
---
Run `bash "${CLAUDE_SKILL_DIR}/../../scripts/queue/status.sh"` and present the result as a compact table.
Then list task ids and titles for `review/` (waiting for the user) and `failed/` (with the `## Failure` reason from each file). Do not change anything.
