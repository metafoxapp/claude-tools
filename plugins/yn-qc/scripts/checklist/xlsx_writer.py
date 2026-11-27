"""Write the six-sheet QC workbook (Overview, Account testing, Checklist, RTM, Summary, Issue Log)."""
import math

from openpyxl import Workbook
from openpyxl.formatting.rule import CellIsRule
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.worksheet.datavalidation import DataValidation

from qcdata import ISSUE_STATUSES, PRIORITIES, TC_STATUSES

FONT = "Arial"
DARK, HEAD, LABEL, ZEBRA = "1F4E79", "2E75B6", "D6E4F0", "F0F7FF"
YELLOW = "FFFF00"
STATUS_FILL = {"PASS": "C6EFCE", "FAIL": "FFC7CE", "KNOWN GAP": "FFEB9C", "BLOCKED": "F4B183",
               "N/A": "D9D9D9", "NOT TESTED": "FFFFFF"}
RESULT_FILL = {"PASS": "C6EFCE", "FAIL": "FFC7CE", "KNOWN GAP": "FFEB9C", "N/A": "D9D9D9",
               "PARTIAL": "DDEBF7", "NOT TESTED": "FFFFFF", "NO COVERAGE": "FF0000"}
ISSUE_FILL = {"Pass": "C6EFCE", "Fail": "FFC7CE", "Open for coding": "FFEB9C", "N/A": "D9D9D9"}
PRIORITY_COLOR = {"Critical": "C00000", "High": "C00000", "Medium": "C55A00", "Low": "548235"}
LEGEND = {"PASS": "Actual matches expected", "FAIL": "Defect or deviation found — see Notes / ticket",
          "KNOWN GAP": "Documented as a known gap / not built", "BLOCKED": "Cannot test until another issue is fixed",
          "N/A": "Out of current scope", "NOT TESTED": "Not executed yet"}
THIN = Side(style="thin", color="BFBFBF")
BORDER = Border(left=THIN, right=THIN, top=THIN, bottom=THIN)
RESULT_FORMULA = ('=IF(G{r}=0,"NO COVERAGE",IF(I{r}>0,"FAIL",IF(J{r}>0,"KNOWN GAP",IF(K{r}=G{r},"N/A",'
                  'IF(H{r}+K{r}=G{r},"PASS",IF(H{r}>0,"PARTIAL","NOT TESTED"))))))')


def fill(c):
    return PatternFill("solid", fgColor=c)


def font(sz=10, bold=False, color="000000"):
    return Font(name=FONT, sz=sz, b=bold, color=color)


def lines(text, width):
    return sum(max(1, math.ceil(len(part) / max(width, 1))) for part in str(text).split("\n"))


def fit_height(row_values, widths, sz):
    """Row height from the tallest wrapped cell (approximate, Arial)."""
    n = max((lines(v, w * 1.05) for v, w in zip(row_values, widths) if v not in (None, "")), default=1)
    return max(15.75, n * (sz + 3.5) + 4)


def set_widths(ws, widths):
    for i, w in enumerate(widths):
        ws.column_dimensions[chr(65 + i)].width = w


def title(ws, text, last_col, sz=13):
    ws["A1"] = text
    ws.merge_cells(f"A1:{last_col}1")
    ws["A1"].font = font(sz, True, "FFFFFF")
    ws["A1"].fill = fill(DARK)
    ws["A1"].alignment = Alignment(horizontal="center", vertical="center")
    ws.row_dimensions[1].height = 25.5


def header(ws, row, cols, sz=11, yellow_from=None):
    for j, h in enumerate(cols, 1):
        c = ws.cell(row, j, h)
        user = yellow_from is not None and j >= yellow_from
        c.font = font(sz, True, "000000" if user else "FFFFFF")
        c.fill = fill(YELLOW if user else HEAD)
        c.border = BORDER
        c.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
    ws.row_dimensions[row].height = 30


def body(ws, row, values, widths, sz, center=(), zebra=True, bold=(), colors=None):
    bg = ZEBRA if zebra and row % 2 == 0 else "FFFFFF"
    for j, v in enumerate(values, 1):
        c = ws.cell(row, j, v)
        c.font = font(sz, (j in bold), (colors or {}).get(j, "000000"))
        c.fill = fill(bg)
        c.border = BORDER
        c.alignment = Alignment(horizontal="center" if j in center else None, vertical="top", wrap_text=True)
    ws.row_dimensions[row].height = fit_height(values, widths, sz)


def status_cf(ws, rng, col, fills):
    for text, color in fills.items():
        ws.conditional_formatting.add(rng, CellIsRule(operator="equal", formula=[f'"{text}"'], fill=fill(color)))


def overview(ws, ck, reach):
    p = ck.project
    set_widths(ws, [26, 90])
    title(ws, f"{p['name'].upper()} — QC CHECKLIST & RTM", "B", 15)
    ws.row_dimensions[1].height = 33.75
    rows = [("Project", p["project"]), ("Document version", p["version"]), ("Requirement sources", p["sources"]),
            ("Test site", p["test_site"]),
            ("Sheets", "Account testing (test accounts) · Checklist (test cases) · RTM (requirement → test case "
                       "traceability, formulas) · Summary (counts, formulas) · Issue Log (bugs/clarifications)"),
            ("How to use", "Update only the Status, Tester and Notes columns (yellow header) in Checklist. "
                           "RTM and Summary recalculate automatically. "
                           f"Rows after row {reach} of Checklist are not counted."),
            ("Scope note", p["scope_note"] or "—")]
    r = 3
    for label, text in rows:
        a, b = ws.cell(r, 1, label), ws.cell(r, 2, text)
        a.font, a.fill = font(10, True), fill(LABEL)
        b.font, b.alignment = font(10), Alignment(wrap_text=True, vertical="top")
        ws.row_dimensions[r].height = fit_height([label, text], [26, 90], 10)
        r += 1

    def band(row, text):
        c = ws.cell(row, 1, text)
        c.font, c.fill = font(10, True, "FFFFFF"), fill(DARK)

    r += 1
    band(r, "STATUS LEGEND")
    for s in TC_STATUSES:
        r += 1
        a = ws.cell(r, 1, s)
        a.font, a.fill, a.alignment = font(9, True), fill(STATUS_FILL[s]), Alignment(horizontal="center")
        ws.cell(r, 2, LEGEND[s]).font = font(9)
    r += 2
    band(r, "PRIORITY LEGEND")
    for label, text in [("Critical", "P0 release gate — must be PASS to release"),
                        ("High / Medium / Low", "Planned by order of importance; not release gates")]:
        r += 1
        ws.cell(r, 1, label).font = font(10)
        ws.cell(r, 2, text).font = font(10)
    r += 2
    band(r, "CHANGE LOG")
    for date, text in p["changelog"]:
        r += 1
        ws.cell(r, 1, date).font = font(10)
        c = ws.cell(r, 2, text)
        c.font, c.alignment = font(10), Alignment(wrap_text=True, vertical="top")
        ws.row_dimensions[r].height = fit_height([date, text], [26, 90], 10)


def accounts(ws, ck):
    widths = [20, 28, 30, 14, 24, 40, 30]
    set_widths(ws, widths)
    title(ws, "TEST ACCOUNTS — PERMISSION TESTING", "G")
    header(ws, 2, ["Role", "Email", "Name", "Status", "Password", "Scope / Grant", "Notes"])
    for i, row in enumerate(ck.accounts):
        body(ws, 3 + i, list(row), widths, 11, bold=(1,))


def checklist(ws, ck, last, reach):
    widths = [10, 13, 22.86, 18, 32.57, 31.43, 44, 13, 10, 13, 12, 53.71]
    set_widths(ws, widths)
    p = ck.project
    title(ws, f"{p['name'].upper()} — QC CHECKLIST v{p['version'].split()[0]} ({len(ck.tcs)} test cases)", "L", 11)
    header(ws, 2, ["TC ID", "Req ID", "Epic", "Feature", "Test Scenario", "Test Steps", "Expected Result",
                   "Type", "Priority", "Status", "Tester", "Notes / Ticket"], yellow_from=10)
    for i, t in enumerate(ck.tcs):
        steps = "\n".join(f"{n}. {s}" for n, s in enumerate(t.steps, 1))
        body(ws, 3 + i, [t.id, t.req_id, t.epic, t.feature, t.scenario, steps, t.expected, t.type, t.priority,
                         t.status, t.tester, t.notes], widths, 11, center=(1, 2, 8, 9, 10, 11),
             bold=(9,), colors={9: PRIORITY_COLOR[t.priority]})
    ws.freeze_panes = "A3"
    ws.auto_filter.ref = f"A2:L{last}"
    status_cf(ws, f"J3:J{reach}", "J", STATUS_FILL)
    for col, values in (("J", TC_STATUSES), ("I", PRIORITIES)):
        dv = DataValidation(type="list", formula1='"' + ",".join(values) + '"', allow_blank=True)
        ws.add_data_validation(dv)
        dv.add(f"{col}3:{col}{reach}")


def rtm(ws, ck, reach, last_req):
    widths = [10, 46, 26, 30, 22, 28, 7, 8, 8, 11, 7, 14, 12, 18]
    set_widths(ws, widths)
    title(ws, "REQUIREMENTS TRACEABILITY MATRIX — Requirements → Test Cases", "N", 12)
    header(ws, 2, ["Req ID", "Requirement (User Story / NFR)", "Epic", "PRD Reference", "Doc Status",
                   "Linked Test Cases", "# TC", "# PASS", "# FAIL", "# KNOWN GAP", "# N/A",
                   "# NOT TESTED / BLOCKED", "Coverage", "Requirement Result"], sz=9)
    B, J = f"Checklist!$B$3:$B${reach}", f"Checklist!$J$3:$J${reach}"
    for i, (rid, text, epic, prd, doc) in enumerate(ck.reqs):
        r = 3 + i
        linked = ", ".join(t.id for t in ck.tcs if t.req_id == rid)
        count = lambda s: f'=COUNTIFS({B},A{r},{J},"{s}")'
        body(ws, r, [rid, text, epic, prd, doc, linked, f"=COUNTIF({B},A{r})", count("PASS"), count("FAIL"),
                     count("KNOWN GAP"), count("N/A"),
                     f'=COUNTIFS({B},A{r},{J},"NOT TESTED")+COUNTIFS({B},A{r},{J},"BLOCKED")',
                     f'=IF(G{r}=0,"NO COVERAGE","COVERED")', RESULT_FORMULA.format(r=r)],
             widths, 9, center=(1, 7, 8, 9, 10, 11, 12, 13, 14), zebra=False)
    ws.freeze_panes = "C3"
    ws.auto_filter.ref = f"A2:N{max(last_req, 3)}"
    status_cf(ws, f"N3:N{max(last_req, 3)}", "N", RESULT_FILL)


def summary(ws, ck, reach, last_req):
    set_widths(ws, [34, 10, 10, 10, 12, 10, 13, 10, 10])
    title(ws, f"QC SUMMARY — {ck.project['name'].upper()}", "I", 12)
    er = max(last_req, 3)
    J, C, N = f"Checklist!$J$3:$J${reach}", f"Checklist!$C$3:$C${reach}", f"RTM!$N$3:$N${er}"

    def head(row, cols):
        for j, h in enumerate(cols, 1):
            c = ws.cell(row, j, h)
            c.font, c.fill = font(9, True, "FFFFFF"), fill(HEAD)
            c.alignment = Alignment(horizontal="center", wrap_text=True)

    def block(row, label, pct_label, rng, names, fills):
        head(row, [label, "Count", pct_label])
        first = row + 1
        total = first + len(names)
        for k, name in enumerate(names):
            r = first + k
            ws.cell(r, 1, name).fill = fill(fills[name])
            ws.cell(r, 2, f"=COUNTIF({rng},A{r})")
            ws.cell(r, 3, f"=IFERROR(B{r}/$B${total},0)").number_format = "0%"
        ws.cell(total, 1, "TOTAL").font = font(9, True)
        ws.cell(total, 2, f"=SUM(B{first}:B{total - 1})").font = font(9, True)
        ws.cell(total, 3, f"=IFERROR(B{total}/B{total},0)").number_format = "0%"
        return total

    t1 = block(3, "Test case status", "% of total", J, TC_STATUSES, STATUS_FILL)
    names = ["PASS", "PARTIAL", "FAIL", "KNOWN GAP", "N/A", "NOT TESTED", "NO COVERAGE"]
    t2 = block(t1 + 2, "Requirement result (RTM)", "% of reqs", N, names, RESULT_FILL | {"NO COVERAGE": "FFC7CE"})
    ws.cell(t2 + 1, 1, f"Total requirements in RTM: {len(ck.reqs)}")
    epics = list(dict.fromkeys([r[2] for r in ck.reqs] + [t.epic for t in ck.tcs]))
    row = t2 + 3
    head(row, ["Epic", "# TC", "PASS", "FAIL", "KNOWN GAP", "N/A", "NOT TESTED", "BLOCKED", "% Pass"])
    for k, name in enumerate(epics):
        r = row + 1 + k
        ws.cell(r, 1, name)
        ws.cell(r, 2, f"=COUNTIF({C},A{r})")
        for col, s in zip("CDEFGH", ["PASS", "FAIL", "KNOWN GAP", "N/A", "NOT TESTED", "BLOCKED"]):
            ws[f"{col}{r}"] = f'=COUNTIFS({C},$A{r},{J},"{s}")'
        ws.cell(r, 9, f"=IFERROR(C{r}/(B{r}-F{r}),0)").number_format = "0%"
    ws.cell(row + len(epics) + 2, 1, "% Pass = PASS / (TC − N/A)")
    for r in ws.iter_rows(min_row=3):
        for c in r:
            if c.value is not None and c.font.name != FONT:  # cells written without an explicit font
                c.font = font(9)


def issues(ws, ck):
    widths = [5, 18, 52.71, 12, 12, 13, 12, 19.43, 14, 22.43, 60]
    set_widths(ws, widths)
    header(ws, 1, ["#", "Ticket ID / Ref", "Title", "Type", "Severity", "Req ID", "TC ID", "Status", "Jira Key",
                   "Found In", "Notes"])
    n, r = 0, 1
    for row in ck.issues:
        r += 1
        if isinstance(row, str):
            c = ws.cell(r, 3, row)
            c.font = font(11, True, "666666")
            continue
        n += 1
        body(ws, r, [n, *row], widths, 11, center=(1,), zebra=False)
    last = max(r, 2)
    ws.freeze_panes = "A2"
    ws.auto_filter.ref = f"A1:K{last}"
    status_cf(ws, f"H2:H{last + 500}", "H", ISSUE_FILL)
    dv = DataValidation(type="list", formula1='"' + ",".join(ISSUE_STATUSES) + '"', allow_blank=True)
    ws.add_data_validation(dv)
    dv.add(f"H2:H{last + 500}")


def write(ck, out_path):
    last, last_req = 2 + len(ck.tcs), 2 + len(ck.reqs)
    wb = Workbook()
    wb.remove(wb.active)
    reach = max(last, 3) + 500  # formulas, validation and formatting all cover Checklist rows 3..reach
    overview(wb.create_sheet("Overview"), ck, reach)
    accounts(wb.create_sheet("Account testing"), ck)
    checklist(wb.create_sheet("Checklist"), ck, last, reach)
    rtm(wb.create_sheet("RTM"), ck, reach, last_req)
    summary(wb.create_sheet("Summary"), ck, reach, last_req)
    issues(wb.create_sheet("Issue Log"), ck)
    wb.save(out_path)
