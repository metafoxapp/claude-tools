# Hướng dẫn điền file Checklist + RTM

Dành cho tester. File Excel do skill checklist-gen dựng; bạn chỉ điền vài cột, mọi con số còn lại tự cập nhật.

## 1. File có 6 sheet

| Sheet | Dùng để | Ai sửa |
|---|---|---|
| **Overview** | Thông tin dự án, nguồn requirement, chú giải Status/Priority, change log | Không sửa tay |
| **Account testing** | Tài khoản dùng để test theo từng role | Không sửa tay; gửi thay đổi cho QC lead |
| **Checklist** | Danh sách test case | Chỉ 3 cột vàng: **Status**, **Tester**, **Notes / Ticket** |
| **RTM** | Requirement → test case liên quan, số lượng theo Status, kết quả từng requirement | Tự tính (công thức) |
| **Summary** | Tổng hợp theo Status, theo requirement, theo epic, % Pass | Tự tính (công thức) |
| **Issue Log** | Bug tìm thấy khi test (câu hỏi về requirement nằm ở file Open Questions) | Không sửa tay; gửi thay đổi cho QC lead |

**Chỉ sửa 3 cột Status / Tester / Notes của sheet Checklist.** File được dựng lại từ file dữ liệu, nên mọi chỗ sửa khác (Issue Log, Account testing, Overview…) sẽ mất ở lần dựng sau: muốn đổi chỗ nào thì gửi cho QC lead, QC lead đưa vào file dữ liệu.

Đừng thêm dòng test case bằng tay, đừng xoá hay đổi mã TC: nhờ QC lead thêm vào file dữ liệu rồi dựng lại file.

## 2. Cột nào được điền

Header vàng = cột người test điền: **Status**, **Tester**, **Notes / Ticket**. Các cột còn lại (header xanh) giữ nguyên. Status và Priority có dropdown; ô Status tự đổi màu theo giá trị.

## 3. Ý nghĩa và cách dùng từng Status

| Status | Khi nào dùng |
|---|---|
| **PASS** | Kết quả thực tế khớp mọi ý của Expected Result. Chưa đủ mọi ý thì chưa được ghi PASS |
| **FAIL** | Phát hiện lỗi hoặc lệch so với Expected. Ghi triệu chứng vào Notes; đã tạo ticket thì thêm "Ticket logged." và mã Jira |
| **KNOWN GAP** | Tài liệu ghi rõ chức năng chưa làm / là known gap. Notes nêu nguồn tài liệu |
| **BLOCKED** | Không test tiếp được vì phải chờ lỗi khác được sửa, hoặc môi trường cản trở (dữ liệu còn sót, mạng lỗi). Notes ghi rõ cái gì đang chặn |
| **N/A** | Test case bị đưa ra khỏi scope theo quyết định. Notes ghi lý do và ngày |
| **NOT TESTED** | Chưa chạy |

Quy tắc hay nhầm:

- **Test dở dang** (mới kiểm một phần): giữ **NOT TESTED**, Notes bắt đầu bằng `Partial – ` + đã kiểm gì + còn thiếu gì. Không ghi PASS khi chưa đủ.
- **PM đã chốt một quy tắc** (dù khác PRD) và hệ thống chạy đúng quy tắc đó: ghi **PASS**, Notes dẫn mã câu hỏi, ví dụ `Rule confirmed (Q-SHP-01, 30/10/2026): …`. Không dùng N/A cho trường hợp này.
- **Mã TC không tái sử dụng.** Bỏ khỏi scope thì đổi Status thành **N/A** + ghi lý do, không xoá dòng.

## 4. Priority

`Critical`, `High`, `Medium`, `Low`. **Critical là điều kiện chặn release (release gate)**: các test case Critical (tiền, quyền, trạng thái, luồng chính) phải PASS thì mới release.

## 5. Cách ghi Tester và Notes

- **Tester**: `Tên (môi trường dd/mm/yyyy, tài khoản – role, nền tảng nếu không phải web)`, ví dụ `Linh (staging 30/10/2026, Linh – customer)`.
- **Notes**: cụ thể, kiểm chứng được: mã dữ liệu (đơn #24, sản phẩm 1458), thông báo hiển thị nguyên văn trong ngoặc, số liệu trước/sau, cài đặt đã đổi và đã khôi phục. Không đoán nguyên nhân.
- **Theo từng vòng retest**: thêm một dòng mới ở đầu Notes dạng `[Retest dd/mm] kết quả…`, giữ lịch sử các vòng trước bên dưới, và đổi Status sang kết quả mới.

## 6. Issue Log

Mỗi bug một dòng. Câu hỏi về requirement không ghi ở đây mà ghi vào file Open Questions. Tester không sửa trực tiếp sheet này: gửi thay đổi (dòng mới, Status mới, Jira key, notes) cho QC lead để đưa vào file dữ liệu. Status chỉ có 4 giá trị:

| Status | Khi nào chuyển |
|---|---|
| **Open for coding** | Bug mới đã xác nhận, đang chờ dev sửa |
| **Pass** | Đã sửa, retest thấy đúng |
| **Fail** | Retest vẫn lỗi |
| **N/A** | Không phải lỗi hoặc ngoài scope |

Luồng thường gặp: bug mới → `Open for coding` → dev sửa → retest → `Pass` (hoặc `Fail` nếu còn lỗi, rồi quay lại chờ sửa). Khi Status ở Issue Log đổi, nhớ cập nhật Status của test case tương ứng trong Checklist (cột bạn được sửa).

## 7. Account testing

Tester không sửa sheet này, gửi thay đổi tài khoản cho QC lead. Chỉ ghi tài khoản của **site test**: role, tên, trạng thái và quyền/scope được cấp. Không ghi mật khẩu thật vào file; chỉ ghi nơi lưu (ví dụ "xem trong trình quản lý mật khẩu của team").

## 8. Open Questions (file .md gửi PM)

Khi tài liệu mâu thuẫn hoặc thiếu thông tin, QC lập câu hỏi `Q-<PREFIX>-NN` và gửi file Open Questions cho PM.

- **PM trả lời**: điền vào dòng **Trả lời PM** của từng câu, ghi rõ chọn phương án nào (A/B/…) hoặc mô tả quy tắc đúng. Nếu câu trả lời làm đổi tiêu chí chấp nhận, nhờ BA sửa thẳng vào AC.
- **4 trạng thái**:
  - `OPEN`: chờ trả lời.
  - `CONFIRMED`: PM đã chốt, QC đã cập nhật Expected trong checklist.
  - `RESOLVED (doc)`: tài liệu đã trả lời; QC đã cập nhật checklist, PM chỉ cần phản hồi nếu không đồng ý.
  - `PARTIAL`: mới trả lời một phần, phần còn lại vẫn chờ PM.
- Test case bị chặn bởi câu hỏi nào thì Notes ghi mã câu đó; khi câu hỏi được chốt, cập nhật Expected, bỏ chữ "(pending …)" và retest.
