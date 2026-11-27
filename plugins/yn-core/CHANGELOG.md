# Changelog: yn-core

## 0.1.1

- Sửa race của khóa trong `add.sh` và `worker.sh`: khóa giờ thuộc về tiến trình tạo được file `owner` bằng redirect độc quyền (noclobber), không chỉ dựa vào `mkdir`. Một số bản `mkdir` báo thành công khi tiến trình khác vừa tạo thư mục trước, làm hai lệnh `add` song song lấy trùng ID (CI trên Ubuntu 26.04 đỏ ở `test_add.sh`).

## 0.1.0

- Khung đầu tiên: `queue-init`, `queue-add`, `queue-triage`, `queue-run`, `queue-status`.
- Agent `queue-worker` (một nhóm một worktree), Stop hook tùy chọn (`.yn/queue/.autorun`).
- Worker headless `worker.sh` (verify độc lập, retry, không push).
- Preset: generic, laravel, node, java-e2e.
