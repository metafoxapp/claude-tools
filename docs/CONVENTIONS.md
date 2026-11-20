# Quy ước của repo claude-tools

Mọi quy ước dưới đây được `scripts/validate.sh` kiểm tra tự động (chạy trong CI). Sửa quy ước thì sửa cả script.

## 1. Cấu trúc

- **Marketplace:** `yn-tools` (`.claude-plugin/marketplace.json`).
- **Plugin theo role:** một plugin cho mỗi role, đặt tại `plugins/yn-<role>/`.
- **Skill theo công việc:** bên trong plugin, mỗi skill là `skills/<tool>-<verb>/SKILL.md`.

```
plugins/yn-<role>/
  .claude-plugin/plugin.json
  skills/<tool>-<verb>/SKILL.md
  agents/<tên>.md            # tùy chọn
  hooks/hooks.json           # tùy chọn
  scripts/<tool>/            # script dùng chung của tool
  presets/<tool>/  templates/<tool>/
  README.md  CHANGELOG.md
```

## 2. Đặt tên

| Thành phần | Quy tắc | Ví dụ |
|---|---|---|
| Plugin | `yn-<role>`, role thuộc danh sách bên dưới | `yn-core`, `yn-qc` |
| Skill | `<tool>-<verb>`, chữ thường, gạch ngang | `queue-add`, `checklist-gen` |
| Lệnh gọi | `/yn-<role>:<tool>-<verb>` | `/yn-qc:checklist-gen` |
| Agent | tên ngắn, trùng tên file | `queue-worker` |
| Dữ liệu trong project | `.yn/<tool>/` | `.yn/queue/` |
| Biến môi trường | `YN_<TOOL>_*` | `YN_QUEUE_DIR` |

**Role** (chọn theo người dùng chính; từ hai vai trò trở lên dùng thì vào `core`):
`core`, `dev`, `qc`, `pm`, `design`, `ops`. Thêm role mới = sửa `ROLES` trong `scripts/validate.sh` và tài liệu này.

**Động từ chuẩn** (cuối tên skill): `init`, `add`, `triage`, `run`, `status`, `list`, `review`, `gen`, `fix`, `report`, `import`.

Tool là **danh từ** mô tả thứ nó quản lý. Không ghi version hay ngày vào tên.

## 3. Skill

- `name` trong frontmatter trùng tên thư mục.
- `description` ngắn (một câu), vì mô tả của mọi skill đã bật đều nạp vào context mỗi phiên.
- Skill có tác dụng phụ (ghi file, commit, chạy nền, đổi cấu hình) đặt `disable-model-invocation: true`.
- Gọi script của plugin qua `${CLAUDE_SKILL_DIR}/../../scripts/<tool>/...`.
- Nội dung SKILL.md và agent viết bằng tiếng Anh (hướng dẫn cho model); tài liệu cho người đọc (README, CONVENTIONS) viết bằng tiếng Việt.

## 4. Phiên bản

- Semver, ghi trong `plugin.json` và `marketplace.json`, hai nơi phải khớp.
- Mỗi plugin có `CHANGELOG.md`. Đổi hành vi hoặc tên skill thì tăng minor (khi < 1.0) hoặc major (từ 1.0).
- Không phụ thuộc chéo giữa các plugin: mỗi plugin được cache riêng. Script dùng chung thì copy vào từng plugin.

## 5. An toàn

- Script không push, không merge, không ghi ngoài thư mục project.
- Hook phải là no-op rẻ ở project không dùng tool (kiểm tra file cờ trước).
- Cấu hình quyền (`permissions`) ghi vào `.claude/settings.json` của project chỉ sau khi người dùng đồng ý.

## 6. Phát hành

1. Sửa code, cập nhật `CHANGELOG.md`, tăng version ở cả hai file.
2. `bash scripts/validate.sh && bash tests/run.sh`.
3. PR vào `main`, CI phải xanh.
