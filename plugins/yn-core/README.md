# yn-core

Công cụ dùng chung cho mọi role. Hiện có một tool: **queue**, hàng đợi task cục bộ. Bạn bổ sung task lúc đang review, Claude phân nhóm rồi implement từng nhóm.

## Cài đặt

```
/plugin marketplace add metafoxapp/claude-tools
/plugin install yn-core@yn-tools
```

## Lệnh

| Lệnh | Việc |
|---|---|
| `/yn-core:queue-init` | Thiết lập `.yn/queue/` trong project, tạo `config.yaml` từ preset |
| `/yn-core:queue-add <mô tả>` | Thêm task vào `inbox`, tự lấy ngữ cảnh từ cuộc trò chuyện |
| `/yn-core:queue-triage` | Phân nhóm, tách task chạm nhiều nhóm, chuyển sang `ready` |
| `/yn-core:queue-run <nhóm>` | Làm các task `ready` của nhóm trong phiên hiện tại |
| `/yn-core:queue-run all` | Mỗi nhóm một subagent, song song, mỗi nhóm một worktree |
| `/yn-core:queue-run --autorun [N]` | Stop hook giữ Claude làm tiếp tối đa N lần (mặc định 20) |
| `/yn-core:queue-run stop` | Tắt autorun |
| `/yn-core:queue-status` | Số task theo trạng thái và theo nhóm |

## Quy trình

```
inbox ──triage──► ready ──claim──► doing ──verify ok──► review ──(người duyệt)──► done
                    ▲                 │
                    └──retry──────────┴──hết lượt──► failed
```

- Mỗi task là một file Markdown trong `.yn/queue/<trạng thái>/T-####.md`. Nhận việc bằng `mv` (nguyên tử), nên hai worker không thể nhận cùng một task.
- Queue luôn nằm ở thư mục gốc **repo chính**, mọi worktree dùng chung qua `git rev-parse --git-common-dir`.
- `config.yaml` (nhóm, đường dẫn, lệnh `verify`) **nên commit** để team dùng chung. Task và log không commit.

## Task cần gì để chạy được

`title`, ít nhất một dòng `Acceptance`, và một lệnh `verify` (của task hoặc của nhóm). Thiếu thì task ở lại `inbox` kèm mục `## Needs`.

## Chạy nền (headless)

`init` sao chép script vào `.yn/queue/bin/` để cron/launchd không trỏ vào thư mục cache có version của plugin:

```bash
.yn/queue/bin/worker.sh backend --max-tasks 5
.yn/queue/bin/worker.sh backend --dry-run
```

Worker tạo worktree `.claude/worktrees/q-<nhóm>` (nhánh `yn-queue/<nhóm>`), gọi `claude -p` với `dontAsk` và danh sách tool hẹp, rồi **tự chạy lại `verify`** thay vì tin báo cáo của Claude. Đạt thì task sang `review`; không đạt thì hoàn tác phần dở, thử lại tới `max_attempts`, quá thì sang `failed`.

## An toàn

- Không push, không merge. Người duyệt từng nhánh nhóm rồi tự merge.
- Worker cấm `git push` và `rm -rf`, giới hạn `max_turns` và `max_budget_usd` mỗi lượt.
- Stop hook là no-op trừ khi có `.yn/queue/.autorun`. Hook tự dừng khi số task `ready` không giảm sau một lần ép tiếp tục, hoặc hết bộ đếm.
- Worker chỉ hoàn tác (`reset --hard`, `clean`) trong worktree riêng của nó.

## Giới hạn đã biết

- `${CLAUDE_SKILL_DIR}` trong SKILL.md và `isolation: worktree` trong agent của plugin cần kiểm chứng thêm trên bản Claude Code đang dùng.
- Parser `config.yaml` là shell/awk, chỉ hiểu đúng dạng trong các preset (nhóm thụt 2 ký tự, khóa thụt 4 ký tự, giá trị một dòng).
- Phụ thuộc `jq` cho Stop hook; thiếu `jq` thì hook không làm gì.
