---
name: queue-init
description: Set up the YN task queue (.yn/queue) in the current project.
argument-hint: "[--preset generic|laravel|node|java-e2e]"
disable-model-invocation: true
allowed-tools: Bash(bash *scripts/queue/init.sh*) Bash(bash *scripts/queue/detect-stack.sh*)
---
Initialise the local task queue for this project.

1. Run `bash "${CLAUDE_SKILL_DIR}/../../scripts/queue/init.sh" $ARGUMENTS` from the project root.
2. Open `.yn/queue/config.yaml` and show the user the groups, their `paths` and `verify` commands. Point out every group whose `verify` is empty: the headless worker refuses to run such a group.
3. Ask the user whether to adjust groups/verify commands to this project; apply their edits to `.yn/queue/config.yaml` (this file is meant to be committed).
4. The script printed a recommended `permissions.deny` block. Show it and ask before merging it into `.claude/settings.json`. Never edit settings without an explicit yes.
5. Tell the user the next steps: `/yn-core:queue-add <task>`, then `/yn-core:queue-triage`, then `/yn-core:queue-run <group>`.
