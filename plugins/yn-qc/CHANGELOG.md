# Changelog: yn-qc

## 0.2.0

Tách `requirement-review` thành hai skill và viết lại sau khi đánh giá chất lượng:

- Skill mới `release-review`: release go/no-go, regression impact, estimate testing, báo cáo QC. Đầu vào là kết quả checklist, bug và open questions.
- `requirement-review` chỉ còn phần trước khi test: phân tích requirement, luồng, scenario, coverage, exploratory, UI, test data, permission matrix, review test case của member.

- Mô tả trigger chuyển sang dạng "Use when…", nêu rõ khi nào dùng và tách khỏi `checklist-gen`, `checklist-import`, `ticket-review` để không tranh nhau trigger. Thêm mục "Not this skill".
- Gộp ba bộ phân loại cũ thành một bảng nhãn duy nhất (Confirmed Requirement, Confirmed Rule, Conflict, Gap, Assumption, Risk, Recommendation). Mỗi nhãn ghi rõ nó trở thành gì trong checklist-gen; Conflict/Gap ứng với `kind` của Open Questions.
- Bảng scenario dùng đúng các cột `TCS` của checklist-gen (Req ID, Epic, Feature, Scenario, Steps, Expected, Type, Priority) và một danh sách Type duy nhất.
- Bỏ công thức risk không có thang điểm, thay bằng tiêu chí cụ thể cho P0–P3 và quy tắc tăng/giảm một mức.
- Release readiness có tiêu chí NO-GO / GO WITH RISK / GO cụ thể dựa trên số liệu checklist.
- Bắt buộc trích nguồn cho mọi mục đã xác nhận; quy định ngôn ngữ output; lệnh nhanh nhận diện theo ý định, có ví dụ tiếng Việt; thêm mục "Common mistakes".

Đồng bộ cả 7 skill sau khi chạy thử một vòng đời trọn vẹn (feature giả định, từ PRD tới release):

- Một quy tắc chung cho mọi skill: decision hoặc câu hỏi đã trả lời ghi đè PRD là yêu cầu đã xác nhận (lệch thì là Bug), không phải Conflict. Conflict chỉ dùng cho các nguồn ngang hàng. Trước đây `checklist-import` và `ticket-review` cho hai kết luận ngược nhau.
- Câu hỏi về requirement chỉ ghi vào Open Questions, ID `Q-<PREFIX>-NN` ở mọi skill. Issue Log chỉ ghi lỗi tìm thấy khi test. Ticket phụ thuộc câu hỏi thì dẫn ID câu hỏi.
- Phân biệt nhãn Gap (tài liệu thiếu thông tin) với trạng thái KNOWN GAP. Giả định "(assumption)" phải thành câu hỏi Gap trước khi vào checklist.
- `requirement-review` là nguồn duy nhất cho tiêu chí priority và danh sách Type (bỏ `Exploratory` khỏi Type). `checklist-gen` và `checklist-import` trỏ sang đó.
- Coverage theo từng luật: khuyên tách mỗi luật kiểm thử được thành một dòng `REQS`, vì `Reqs without TC` chỉ kiểm theo dòng.
- Builder in thêm số đếm theo priority (`Critical: PASS 2, FAIL 1`), sheet Summary có bảng theo priority và dòng release gate. Builder báo lỗi khi TC còn "(pending Q-…)" bị ghi PASS/FAIL.
- Script mới `scripts/checklist/tcs_json.py`: `export` sinh `tcs.json` cho bộ test tự động; `results` đọc `summary.json` của lần chạy (định dạng trong `testrun-report`) và in khối `RESULTS` để dán vào file dữ liệu.
- `retest-run`: "ticket file" chính là Issue Log trong file dữ liệu; ghi Jira key vào đó sau khi tạo ticket.
- Mô tả của cả 7 skill theo dạng "Use when…"; `ticket-review` bỏ định dạng thừa từ pandoc.
- Hướng dẫn tester: Issue Log chỉ ghi bug.

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
