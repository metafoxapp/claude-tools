# Changelog: yn-core

## 0.1.0

- Khung đầu tiên: `queue-init`, `queue-add`, `queue-triage`, `queue-run`, `queue-status`.
- Agent `queue-worker` (một nhóm một worktree), Stop hook tùy chọn (`.yn/queue/.autorun`).
- Worker headless `worker.sh` (verify độc lập, retry, không push).
- Preset: generic, laravel, node, java-e2e.
