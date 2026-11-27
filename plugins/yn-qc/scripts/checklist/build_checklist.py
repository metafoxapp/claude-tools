#!/usr/bin/env python3
"""Build the QC checklist workbook (and optional Open Questions markdown).

Usage: build_checklist.py <data.py> <out.xlsx> [<out_open_questions.md>]
data.py is executed as Python: only use data files you trust.
Exit codes: 0 ok, 2 data errors (one 'ERROR: ...' line each, no file written).
"""
import os
import sys
from collections import Counter

sys.dont_write_bytecode = True  # never leave __pycache__ next to the plugin scripts
try:
    import openpyxl  # noqa: F401
except ImportError:
    print("ERROR: openpyxl is required: python3 -m pip install openpyxl (or use a venv)", file=sys.stderr)
    sys.exit(2)

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import oq_writer  # noqa: E402
import qcdata  # noqa: E402
import xlsx_writer  # noqa: E402


def main(argv):
    if len(argv) not in (3, 4):
        print(__doc__.strip(), file=sys.stderr)
        return 64
    try:
        ck = qcdata.load(argv[1])
    except qcdata.DataError as e:
        for err in e.errors:
            print(f"ERROR: {err}", file=sys.stderr)
        return 2
    try:
        xlsx_writer.write(ck, argv[2])
    except Exception as e:  # last line of defence: report instead of a traceback
        print(f"ERROR: cannot write {argv[2]}: {type(e).__name__}: {e}", file=sys.stderr)
        return 2
    counts = Counter(t.status for t in ck.tcs)
    shown = {s: counts[s] for s in qcdata.TC_STATUSES if counts[s]}
    print(f"Wrote {argv[2]} ({len(ck.tcs)} test cases, {len(ck.reqs)} requirements)")
    print(f"Status {shown}")
    for prio in qcdata.PRIORITIES:
        pc = Counter(t.status for t in ck.tcs if t.priority == prio)
        if pc:
            print(f"{prio}: " + ", ".join(f"{s} {pc[s]}" for s in qcdata.TC_STATUSES if pc[s]))
    covered = {t.req_id for t in ck.tcs}
    missing = [r[0] for r in ck.reqs if r[0] not in covered]
    print("Reqs without TC: " + (", ".join(missing) if missing else "none"))
    if len(argv) == 4:
        oq_writer.write(ck, argv[3])
        print(f"Wrote {argv[3]} ({len(ck.oq)} open questions)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
