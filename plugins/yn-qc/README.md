# yn-qc

Công cụ cho role QC: phân tích requirement, dựng checklist + RTM bằng Excel, quản lý Open Questions, viết ticket Jira, chạy vòng retest UI-only và tóm tắt kết quả chạy test.

## Cài đặt

```
/plugin marketplace add metafoxapp/claude-tools
/plugin install yn-qc@yn-tools
```

## Yêu cầu

`checklist-gen`, `checklist-import` và `retest-run` chạy script Python nên cần `python3` và thư viện `openpyxl`:

```
python3 -m pip install openpyxl
```

Nếu máy không cho cài thẳng, dùng venv: `python3 -m venv .venv && . .venv/bin/activate && python3 -m pip install openpyxl`. Thiếu `openpyxl` thì script in một dòng `ERROR: openpyxl is required: …` và thoát với mã 2.

## Lệnh

| Lệnh | Việc |
|---|---|
| `/yn-qc:requirement-review` | Phân tích requirement, tìm gap, thiết kế scenario, kiểm tra độ phủ (trước khi test) |
| `/yn-qc:release-review` | Release go/no-go, regression impact, estimate, báo cáo QC (từ kết quả test) |
| `/yn-qc:checklist-gen` | Dựng/cập nhật file Checklist + RTM Excel và Open Questions |
| `/yn-qc:checklist-import` | Sinh test case từ PRD/decisions/permission, đồng bộ khi tài liệu đổi |
| `/yn-qc:ticket-review` | Viết và review ticket Jira |
| `/yn-qc:retest-run` | Chạy một vòng retest UI-only bằng Playwright, cập nhật checklist |
| `/yn-qc:testrun-report` | Chạy test tách khỏi agent, chỉ đưa bản tóm tắt cho Claude |

## Dùng trên claude.ai

Đóng gói mỗi skill thành một file zip tự chứa (kèm script, template, hướng dẫn mà skill cần):

```
bash scripts/build-zips.sh
```

Kết quả nằm ở `dist/yn-qc/<skill>.zip`. Trên claude.ai, vào Settings → Capabilities/Skills và tải từng file zip lên. `retest-run` và `checklist-import` dùng skill `checklist-gen` (script, định dạng dữ liệu, quy tắc ghi kết quả), nên khi tải lên claude.ai phải tải cả `checklist-gen.zip`. Thư mục `dist/` không được commit.

## Template

- Mẫu file checklist và dữ liệu mẫu: `templates/checklist/`.
- Hướng dẫn điền cho tester (Status, Tester, Notes, Issue Log, Open Questions): [`docs/checklist-guide.md`](docs/checklist-guide.md).
