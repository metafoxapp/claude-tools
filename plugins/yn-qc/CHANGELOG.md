# Changelog: yn-qc

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
