# ShopLite — Open Questions cần PM xác nhận

| | |
|---|---|
| **Module** | ShopLite 1.0 - cart module |
| **Tài liệu nguồn** | shoplite-prd.md (v1.0) \| shoplite-user-stories.md (v1.0, 3 stories) |
| **Người gửi** | QC team |
| **Ngày gửi** | 2026-01-10 |
| **Hạn trả lời mong muốn** | Nhóm P0 trước khi QC chạy các test case bị chặn; P1–P3 trước vòng regression |

**Cách trả lời:** điền vào dòng **Trả lời PM** của từng câu, ghi rõ chọn phương án nào (A/B/…) hoặc mô tả quy tắc đúng. Câu hỏi nào dẫn tới sửa AC thì nhờ BA cập nhật thẳng vào AC của User Stories, vì QC test theo AC.

**Trạng thái:** `OPEN` = chờ trả lời · `CONFIRMED` = PM đã chốt, QC đã cập nhật expected trong checklist · `RESOLVED (doc)` = tài liệu đã trả lời, QC đã cập nhật checklist; PM chỉ cần phản hồi nếu không đồng ý · `PARTIAL` = tài liệu mới trả lời một phần, phần còn lại vẫn chờ PM.

---

## Tổng hợp

| ID | Chủ đề | Loại | Ưu tiên | TC đang chờ | Trạng thái |
|---|---|---|---|---|---|
| Q-SHP-01 | Guest checkout allowed | Conflict | **P0** | SHP-004, SHP-005 | OPEN |
| Q-SHP-02 | Message when stock runs out | Gap | P2 | (no test case yet) | OPEN |

---

## A. Mâu thuẫn giữa các tài liệu

### Q-SHP-01 — Guest checkout allowed · **P0**
- **A (PRD 4):** Guests can check out.
- **B (US-2.1):** Login is required to check out.
- **Thực tế site test:** The test site lets guests check out.
- **Câu hỏi:** Which option is correct for v1?
- **Docs note:** Align PRD 4 and US-2.1 once confirmed.
- **Trả lời PM:**


---

## B. Thiếu hoặc chưa rõ

### Q-SHP-02 — Message when stock runs out · P2
- **Câu hỏi:** What message is shown when a product goes out of stock while it is in the cart?
- **Trả lời PM:**
