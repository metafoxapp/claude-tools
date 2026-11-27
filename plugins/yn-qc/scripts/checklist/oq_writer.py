"""Write the Open Questions markdown (sent to the PM)."""
import datetime

SECTIONS = [("A", "Conflict", "Mâu thuẫn giữa các tài liệu"), ("B", "Gap", "Thiếu hoặc chưa rõ")]


def _cell(text):
    """Escape pipes so a value cannot break a markdown table row."""
    return str(text).replace("|", "\\|")


def _prio(p):
    return f"**{p}**" if p == "P0" else p


def _status(s):
    return s if s == "OPEN" else f"**{s}**"


def write(ck, out_path):
    p = ck.project
    dates = [d for d, _ in p.get("changelog", [])]
    sent = max(dates) if dates else datetime.date.today().isoformat()
    L = [
        f"# {p['name']} — Open Questions cần PM xác nhận", "",
        "| | |", "|---|---|",
        f"| **Module** | {_cell(p['project'])} |",
        f"| **Tài liệu nguồn** | {_cell(p['sources'])} |",
        "| **Người gửi** | QC team |",
        f"| **Ngày gửi** | {sent} |",
        "| **Hạn trả lời mong muốn** | Nhóm P0 trước khi QC chạy các test case bị chặn; P1–P3 trước vòng regression |",
        "",
        "**Cách trả lời:** điền vào dòng **Trả lời PM** của từng câu, ghi rõ chọn phương án nào (A/B/…) hoặc mô tả quy tắc đúng. "
        "Câu hỏi nào dẫn tới sửa AC thì nhờ BA cập nhật thẳng vào AC của User Stories, vì QC test theo AC.", "",
        "**Trạng thái:** `OPEN` = chờ trả lời · `CONFIRMED` = PM đã chốt, QC đã cập nhật expected trong checklist · "
        "`RESOLVED (doc)` = tài liệu đã trả lời, QC đã cập nhật checklist; PM chỉ cần phản hồi nếu không đồng ý · "
        "`PARTIAL` = tài liệu mới trả lời một phần, phần còn lại vẫn chờ PM.", "",
        "---", "", "## Tổng hợp", "",
        "| ID | Chủ đề | Loại | Ưu tiên | TC đang chờ | Trạng thái |", "|---|---|---|---|---|---|",
    ]
    for qid, q in ck.oq.items():
        tcs = ", ".join(q.get("tcs", [])) or "—"
        L.append(f"| {_cell(qid)} | {_cell(q['topic'])} | {q['kind']} | {_prio(q['priority'])} | {_cell(tcs)} | "
                 f"{_status(q.get('status', 'OPEN'))} |")
    for letter, kind, label in SECTIONS:
        items = [(qid, q) for qid, q in ck.oq.items() if q["kind"] == kind]
        if not items:
            continue
        L += ["", "---", "", f"## {letter}. {label}", ""]
        for qid, q in items:
            L.append(f"### {qid} — {q['topic']} · {_prio(q['priority'])}")
            for label_, source, text in q.get("options", []):
                L.append(f"- **{label_} ({source}):** {text}")
            if q.get("site"):
                L.append(f"- **Thực tế site test:** {q['site']}")
            L.append(f"- **Câu hỏi:** {q['question']}")
            if q.get("docs_note"):
                L.append(f"- **Docs note:** {q['docs_note']}")
            L += [f"- **Trả lời PM:** {q.get('answer', '')}".rstrip(), ""]
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(L).rstrip() + "\n")
