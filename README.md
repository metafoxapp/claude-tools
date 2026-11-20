# claude-tools

Bộ công cụ Claude Code dùng chung (marketplace `yn-tools`). Plugin chia theo role, skill đặt theo công việc.

## Cài đặt

```
/plugin marketplace add metafoxapp/claude-tools
/plugin install yn-core@yn-tools
```

Cài thêm plugin theo role của bạn khi có (`yn-qc`, `yn-dev`, ...). Gõ `/yn-` để xem mọi lệnh, gõ `/yn-core:` để xem lệnh của một role.

## Plugin hiện có

| Plugin | Role | Nội dung |
|---|---|---|
| [`yn-core`](plugins/yn-core/README.md) | dùng chung | `queue-*`: hàng đợi task cục bộ, tự phân nhóm, tự implement |

## Quy ước

Xem [docs/CONVENTIONS.md](docs/CONVENTIONS.md). Kiểm tra bằng:

```bash
bash scripts/validate.sh
bash tests/run.sh
```

## Thử plugin khi đang phát triển

```bash
claude --plugin-dir ./plugins/yn-core
```
