"""Diff a hand-edited checklist workbook against its data file.

Usage: python3 diff_user_edits.py <user_copy.xlsx> <data.py>

Reads Status / Tester / Notes (columns J, K, L) of the Checklist sheet and
prints every TC whose values differ from RESULTS, then a RESULTS block to
paste into data.py. SECURITY: data.py is executed; only use files you trust.
"""
import json
import os
import sys

sys.dont_write_bytecode = True  # never leave __pycache__ next to the plugin scripts
try:
    import openpyxl  # noqa: F401
except ImportError:
    print("ERROR: openpyxl is required: python3 -m pip install openpyxl (or use a venv)", file=sys.stderr)
    sys.exit(2)

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qcdata import DataError, load  # noqa: E402

DEFAULT = ("NOT TESTED", "", "")
HEADER_ROWS = 2


def _text(v):
    return "" if v is None else str(v).strip()


def read_sheet(path, prefix):
    from openpyxl import load_workbook
    try:
        wb = load_workbook(path, data_only=True)
    except Exception as e:
        raise DataError([f"cannot read {path}: {type(e).__name__}: {e}"])
    if "Checklist" not in wb.sheetnames:
        raise DataError([f"{path} has no Checklist sheet"])
    ws = wb["Checklist"]
    found = {}
    for r in range(HEADER_ROWS + 1, ws.max_row + 1):
        tid = _text(ws.cell(r, 1).value)
        if not tid.startswith(prefix + "-"):
            continue
        found[tid] = (_text(ws.cell(r, 10).value) or "NOT TESTED",
                      _text(ws.cell(r, 11).value), _text(ws.cell(r, 12).value))
    return found


def main(argv):
    if len(argv) != 3:
        print("usage: diff_user_edits.py <user_copy.xlsx> <data.py>", file=sys.stderr)
        return 2
    try:
        cl = load(argv[2])
        sheet = read_sheet(argv[1], cl.project["prefix"])
    except DataError as e:
        for msg in e.errors:
            print(f"ERROR: {msg}")
        return 2
    new_results, lines, notes = {}, [], []
    for tc in cl.tcs:
        if tc.id not in sheet:
            if tc.id in cl.results:
                new_results[tc.id] = tuple((tuple(cl.results[tc.id]) + ("", ""))[:3])
                notes.append(f"NOTE: {tc.id} not found in sheet, kept existing result")
            continue
        old = tuple(cl.results.get(tc.id, DEFAULT))
        old = (old + ("", ""))[:3]
        new = sheet[tc.id]
        if new != old:
            line = f"{tc.id}: {old[0]} -> {new[0]}"
            if new[0] == old[0]:
                line += "  (tester/notes changed)"
            lines.append(line)
        if new != DEFAULT or tc.id in cl.results:
            new_results[tc.id] = new
    print("\n".join(lines + notes))
    print(f"{len(lines)} TC(s) changed by the user.")
    print("\nRESULTS = {")
    for tid, (s, t, n) in new_results.items():
        print(f"    {json.dumps(tid)}: ({json.dumps(s, ensure_ascii=False)}, "
              f"{json.dumps(t, ensure_ascii=False)}, {json.dumps(n, ensure_ascii=False)}),")
    print("}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
