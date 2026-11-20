---
name: queue-add
description: Queue a task for later, capturing its context from the current conversation. Use when the user wants to add work to the YN task queue instead of doing it now.
argument-hint: <task description>
allowed-tools: Bash(bash *scripts/queue/add.sh*)
---
Add ONE task to the queue. Do not implement it.

1. The task is: $ARGUMENTS. If that is empty, ask what to queue.
2. Gather context from this conversation: file paths, symptoms, decisions taken during review, constraints. Do not invent facts. Long conversations get compacted, so the task file must stand on its own.
3. Acceptance criteria: at least one testable line. If the conversation implies them, write them and mark them `(assumed)`. If you truly cannot infer any, ask ONE short question.
4. Start from the template at `${CLAUDE_SKILL_DIR}/../../templates/queue/task.md`. Fill `title`, `touches` (best-guess paths), `source` (e.g. "review of <topic>"), `priority` (1 = urgent … 5 = low, default 3). Leave `group` empty unless the user named one; triage assigns it. Leave `verify` empty unless the user gave a command.
5. Pipe the finished file to the script, for example with a heredoc:
   `bash "${CLAUDE_SKILL_DIR}/../../scripts/queue/add.sh" <<'TASK' … TASK`
   The script allocates the id; report it (e.g. T-0012) and the inbox path.
6. If several unrelated tasks were mentioned, add them one by one, each with its own context.
