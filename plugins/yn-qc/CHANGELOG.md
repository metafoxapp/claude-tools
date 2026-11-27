# Changelog: yn-qc

## 0.2.0

`requirement-review` được viết lại sau khi đánh giá chất lượng skill:

- Mô tả trigger chuyển sang dạng "Use when…", nêu rõ khi nào dùng và tách khỏi `checklist-gen`, `checklist-import`, `ticket-review` để không tranh nhau trigger. Thêm mục "Not this skill".
- Gộp ba bộ phân loại cũ thành một bảng nhãn duy nhất (Confirmed Requirement, Confirmed Rule, Conflict, Gap, Assumption, Risk, Recommendation). Mỗi nhãn ghi rõ nó trở thành gì trong checklist-gen; Conflict/Gap ứng với `kind` của Open Questions.
- Bảng scenario dùng đúng các cột `TCS` của checklist-gen (Req ID, Epic, Feature, Scenario, Steps, Expected, Type, Priority) và một danh sách Type duy nhất.
- Bỏ công thức risk không có thang điểm, thay bằng tiêu chí cụ thể cho P0–P3 và quy tắc tăng/giảm một mức.
- Release readiness có tiêu chí NO-GO / GO WITH RISK / GO cụ thể dựa trên số liệu checklist.
- Bắt buộc trích nguồn cho mọi mục đã xác nhận; quy định ngôn ngữ output; lệnh nhanh nhận diện theo ý định, có ví dụ tiếng Việt; thêm mục "Common mistakes".

## 0.1.0

Bản đầu tiên của plugin.

- Sáu skill: `requirement-review`, `checklist-gen`, `checklist-import`, `ticket-review`, `retest-run`, `testrun-report`. Skill ghi file (`checklist-gen`, `checklist-import`, `retest-run`) có `disable-model-invocation: true`.
- Phần chữ Testing Estimation trong `requirement-review` là nội dung mới, viết riêng cho plugin này, không lấy từ skill nào có sẵn.
- Bộ dựng checklist (`scripts/checklist/build_checklist.py`): từ một file dữ liệu `data.py` dựng workbook 6 sheet (Overview, Account testing, Checklist, RTM, Summary, Issue Log) và file Open Questions dạng Markdown. Dữ liệu sai thì thoát với mã 2 và in từng dòng `ERROR: …`, không ghi file, không traceback.
- `scripts/checklist/diff_user_edits.py`: so file Excel mà người dùng đã sửa tay với file dữ liệu, in các TC đổi Status/Tester/Notes và khối `RESULTS` để dán lại.
- Template trong `templates/checklist/`: file Excel mẫu, `empty_data.py`, `example_data.py` (sản phẩm giả định ShopLite) và `open-questions.md`.
- `docs/checklist-guide.md`: hướng dẫn tester điền file (Status, Tester, Notes, Issue Log, Open Questions).
- `scripts/build-zips.sh` (ở gốc repo): đóng gói từng skill thành zip tự chứa cho claude.ai. `checklist-gen` phải được tải lên cùng `checklist-import` và `retest-run`.
- Yêu cầu: `python3` và `openpyxl` (`python3 -m pip install openpyxl`, nên dùng venv).
