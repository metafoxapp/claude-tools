"""Export tcs.json for an automated suite, or fold an automated run back into RESULTS.

Usage:
  python3 tcs_json.py export <data.py> <tcs.json>
  python3 tcs_json.py results <data.py> <summary.json> --tester "<who and where>"

export writes one entry per test case, same IDs and order as the Checklist sheet:
  {"project": ..., "prefix": ..., "tests": [{"id", "req_id", "epic", "feature",
   "title", "steps", "expected", "type", "priority"}]}
results reads the run summary (testrun-report format):
  {"results": [{"id": "SHP-001", "status": "passed|failed|flaky|skipped", "message": "..."}]}
and prints the changed TCs and a complete RESULTS block to paste into data.py.
passed -> PASS, failed -> FAIL, flaky -> NOT TESTED (note "Flaky"), skipped -> unchanged.
A test case whose expected result is still "(pending Q-…)" is never set to PASS/FAIL.
Exit codes: 0 ok, 2 errors (one 'ERROR: ...' line each). SECURITY: data.py is executed.
"""
import json
import os
import sys

sys.dont_write_bytecode = True  # never leave __pycache__ next to the plugin scripts
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qcdata import DataError, load  # noqa: E402

MAP = {"passed": "PASS", "failed": "FAIL", "flaky": "NOT TESTED"}


def export(data_path, out_path):
    cl = load(data_path)
    doc = {"project": cl.project["name"], "prefix": cl.project["prefix"],
           "tests": [{"id": t.id, "req_id": t.req_id, "epic": t.epic, "feature": t.feature, "title": t.scenario,
                      "steps": t.steps, "expected": t.expected, "type": t.type, "priority": t.priority}
                     for t in cl.tcs]}
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(doc, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"Wrote {out_path} ({len(doc['tests'])} tests)")


def results(data_path, summary_path, tester):
    cl = load(data_path)
    try:
        with open(summary_path, encoding="utf-8") as f:
            rows = json.load(f)["results"]
        assert isinstance(rows, list)
    except Exception as e:
        raise DataError([f"cannot read {summary_path}: expected {{\"results\": [...]}} ({type(e).__name__}: {e})"])
    by_id = {t.id: t for t in cl.tcs}
    new = {tid: tuple((tuple(v) + ("", ""))[:3]) for tid, v in cl.results.items()}
    lines, notes = [], []
    for row in rows:
        tid, status = str(row.get("id", "")), str(row.get("status", "")).lower()
        msg = str(row.get("message", "") or "").strip()
        if tid not in by_id:
            notes.append(f"NOTE: {tid or '(no id)'} is not a test case in {data_path}, ignored")
            continue
        if status == "skipped":
            continue
        if status not in MAP:
            notes.append(f"NOTE: {tid} has unknown status {status!r}, ignored")
            continue
        value = MAP[status]
        if value in ("PASS", "FAIL") and "(pending Q-" in str(by_id[tid].expected):
            notes.append(f"NOTE: {tid} {status} but its expected result is pending an open question, kept as BLOCKED")
            value = "BLOCKED"
            msg = f"Automated run {status}; expected result pending an open question" + (f": {msg}" if msg else "")
        note = "Flaky" + (f": {msg}" if msg else "") if status == "flaky" else msg
        old = new.get(tid, ("NOT TESTED", "", ""))
        if old[0] != value:
            lines.append(f"{tid}: {old[0]} -> {value}")
        new[tid] = (value, tester, note)
    print("\n".join(lines + notes))
    print(f"{len(lines)} TC(s) changed by the run.")
    print("\nRESULTS = {")
    for tc in cl.tcs:
        if tc.id in new:
            s, t, n = new[tc.id]
            print(f"    {json.dumps(tc.id)}: ({json.dumps(s, ensure_ascii=False)}, "
                  f"{json.dumps(t, ensure_ascii=False)}, {json.dumps(n, ensure_ascii=False)}),")
    print("}")


def main(argv):
    try:
        if len(argv) == 4 and argv[1] == "export":
            export(argv[2], argv[3])
        elif len(argv) == 6 and argv[1] == "results" and argv[4] == "--tester" and argv[5].strip():
            results(argv[2], argv[3], argv[5].strip())
        else:
            print(__doc__.strip(), file=sys.stderr)
            return 2
    except DataError as e:
        for msg in e.errors:
            print(f"ERROR: {msg}", file=sys.stderr)
        return 2
    except OSError as e:
        print(f"ERROR: {type(e).__name__}: {e}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
