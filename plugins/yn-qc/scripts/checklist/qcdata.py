"""Load and validate a checklist data file (data.py).

SECURITY: a data file is executed as Python. Only load data files you trust
(your own or your team's); never load one from an unknown source.
"""
import importlib.util
import os
import re
from dataclasses import dataclass, field

TC_STATUSES = ["PASS", "FAIL", "KNOWN GAP", "BLOCKED", "N/A", "NOT TESTED"]
PRIORITIES = ["Critical", "High", "Medium", "Low"]
ISSUE_STATUSES = ["Pass", "Fail", "Open for coding", "N/A"]
OQ_STATUSES = ["OPEN", "CONFIRMED", "RESOLVED (doc)", "PARTIAL"]
OQ_KINDS = ["Conflict", "Gap"]
OQ_PRIORITIES = ["P0", "P1", "P2", "P3"]


# Characters openpyxl refuses to write into a cell (control characters).
ILLEGAL_CHARS = re.compile(r"[\000-\010\013\014\016-\037]")


def _scan_illegal(value, label, errors):
    """Report every string holding a character that cannot be written to xlsx."""
    if isinstance(value, str):
        if ILLEGAL_CHARS.search(value):
            errors.append(f"{label}: contains a control character that cannot be written to xlsx")
    elif isinstance(value, dict):
        for k, v in value.items():
            _scan_illegal(v, f"{label}[{k!r}]", errors)
    elif isinstance(value, (list, tuple)):
        for i, v in enumerate(value, 1):
            _scan_illegal(v, f"{label}[{i}]", errors)


def _is_seq(v):
    return isinstance(v, (list, tuple))


class DataError(Exception):
    def __init__(self, errors):
        super().__init__("; ".join(errors))
        self.errors = list(errors)


@dataclass
class TC:
    id: str
    req_id: str
    epic: str
    feature: str
    scenario: str
    steps: list
    expected: str
    type: str
    priority: str
    status: str = "NOT TESTED"
    tester: str = ""
    notes: str = ""


@dataclass
class Checklist:
    project: dict
    accounts: list = field(default_factory=list)
    reqs: list = field(default_factory=list)
    tcs: list = field(default_factory=list)
    results: dict = field(default_factory=dict)
    issues: list = field(default_factory=list)
    oq: dict = field(default_factory=dict)


def _exec(path):
    spec = importlib.util.spec_from_file_location("qc_data_file", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def load(path):
    """Read data.py, validate everything, raise DataError with ALL problems."""
    if not os.path.isfile(path):
        raise DataError([f"data file not found: {path}"])
    try:
        d = _exec(path)
    except Exception as e:  # the data file is user code: report, don't crash
        raise DataError([f"cannot load {path}: {type(e).__name__}: {e}"])

    errors = []
    for name in ("PROJECT", "REQS", "TCS"):
        if not hasattr(d, name):
            errors.append(f"{name} is missing")
    if errors:
        raise DataError(errors)

    if not isinstance(d.PROJECT, dict):
        raise DataError(["PROJECT must be a dict"])
    for name in ("REQS", "TCS"):
        if not _is_seq(getattr(d, name)):
            errors.append(f"{name} must be a list")
    if errors:
        raise DataError(errors)
    project = dict(d.PROJECT)
    for key in ("name", "prefix", "project", "version", "sources", "test_site"):
        if not project.get(key):
            errors.append(f"PROJECT.{key} is missing")
        elif not isinstance(project[key], str):
            errors.append(f"PROJECT.{key} must be a string (put it in quotes), got {type(project[key]).__name__}")
    if not isinstance(project.get("scope_note", ""), str):
        errors.append("PROJECT.scope_note must be a string")
    if not _is_seq(project.get("changelog", [])) or not all(
            _is_seq(c) and len(c) == 2 and all(isinstance(x, str) for x in c) for c in project.get("changelog", [])):
        errors.append("PROJECT.changelog must be a list of (date, text) string pairs")
        project["changelog"] = []
    project.setdefault("scope_note", "")
    project.setdefault("changelog", [])
    prefix = project.get("prefix", "")
    if not isinstance(prefix, str):
        prefix = ""

    reqs = list(d.REQS)
    req_ids = set()
    for i, r in enumerate(reqs, 1):
        if not _is_seq(r):
            errors.append(f"REQS[{i}]: must be a list or tuple of 5 fields")
            continue
        if len(r) != 5:
            errors.append(f"REQS[{i}]: expected 5 fields, got {len(r)}")
            continue
        if r[0] in req_ids:
            errors.append(f"REQS: duplicate Req ID {r[0]}")
        req_ids.add(r[0])

    tcs = []
    for i, row in enumerate(d.TCS, 1):
        tid = f"{prefix}-{i:03d}"
        if not _is_seq(row):
            errors.append(f"{tid}: must be a list or tuple of 8 fields")
            continue
        if len(row) != 8:
            errors.append(f"{tid}: expected 8 fields, got {len(row)}")
            continue
        req_id, epic, feature, scenario, steps, expected, typ, prio = row
        if req_id not in req_ids:
            errors.append(f"{tid}: unknown Req ID {req_id}")
        if prio not in PRIORITIES:
            errors.append(f"{tid}: bad priority {prio} (use {', '.join(PRIORITIES)})")
        steps_list = [s.strip() for s in str(steps).split("|") if s.strip()]
        tcs.append(TC(tid, req_id, epic, feature, scenario, steps_list, expected, typ, prio))

    by_id = {t.id: t for t in tcs}
    raw_results = getattr(d, "RESULTS", {})
    if not isinstance(raw_results, dict):
        errors.append("RESULTS must be a dict")
        raw_results = {}
    results = dict(raw_results)
    for tid, val in results.items():
        if tid not in by_id:
            errors.append(f"RESULTS: unknown TC {tid}")
            continue
        if not _is_seq(val) or not 2 <= len(val) <= 3 or not all(isinstance(x, str) for x in val):
            errors.append(f"RESULTS {tid}: expected (status, tester[, notes]) as strings, got {val!r}")
            continue
        status, tester, notes = (tuple(val) + ("", ""))[:3]
        if status not in TC_STATUSES:
            errors.append(f"RESULTS {tid}: bad status {status} (use {', '.join(TC_STATUSES)})")
            continue
        if status in ("PASS", "FAIL") and "(pending Q-" in str(by_id[tid].expected):
            errors.append(f"RESULTS {tid}: {status} while the expected result is still '(pending Q-…)'; "
                          "use BLOCKED until the question is answered, then update the expected result")
            continue
        by_id[tid].status, by_id[tid].tester, by_id[tid].notes = status, tester, notes

    raw_issues = getattr(d, "ISSUES", [])
    if not _is_seq(raw_issues):
        errors.append("ISSUES must be a list")
        raw_issues = []
    issues = list(raw_issues)
    for i, row in enumerate(issues, 1):
        if isinstance(row, str):
            continue
        if not _is_seq(row):
            errors.append(f"ISSUES[{i}]: must be a string (group label) or a list of 10 fields")
            continue
        if len(row) != 10:
            errors.append(f"ISSUES[{i}]: expected 10 fields, got {len(row)}")
            continue
        ref, _, _, _, req_id, tc_id, status = row[:7]
        if req_id and req_id not in req_ids:
            errors.append(f"ISSUES {ref}: unknown Req ID {req_id}")
        if tc_id and tc_id not in by_id:
            errors.append(f"ISSUES {ref}: unknown TC {tc_id}")
        if status not in ISSUE_STATUSES:
            errors.append(f"ISSUES {ref}: bad status {status} (use {', '.join(ISSUE_STATUSES)})")

    raw_oq = getattr(d, "OQ", {})
    if not isinstance(raw_oq, dict):
        errors.append("OQ must be a dict")
        raw_oq = {}
    oq = dict(raw_oq)
    for qid, q in oq.items():
        if not isinstance(q, dict):
            errors.append(f"OQ {qid}: must be a dict")
            continue
        for key in ("topic", "question", "kind", "priority"):
            if not q.get(key):
                errors.append(f"OQ {qid}: {key} is missing")
        if q.get("kind") and q["kind"] not in OQ_KINDS:
            errors.append(f"OQ {qid}: bad kind {q['kind']} (use {', '.join(OQ_KINDS)})")
        if q.get("priority") and q["priority"] not in OQ_PRIORITIES:
            errors.append(f"OQ {qid}: bad priority {q['priority']}")
        if q.get("status", "OPEN") not in OQ_STATUSES:
            errors.append(f"OQ {qid}: bad status {q['status']} (use {', '.join(OQ_STATUSES)})")
        tcs_ = q.get("tcs", [])
        if not _is_seq(tcs_) or not all(isinstance(t, str) for t in tcs_):
            errors.append(f"OQ {qid}: tcs must be a list of strings")
            tcs_ = []
        opts = q.get("options", [])
        if not _is_seq(opts) or not all(_is_seq(o) and len(o) == 3 for o in opts):
            errors.append(f"OQ {qid}: options must be a list of (label, source, text) triples")
        for t in tcs_:
            if t.startswith(prefix + "-") and t not in by_id:  # free text like "(none yet)" is allowed
                errors.append(f"OQ {qid}: unknown TC {t}")

    accounts = getattr(d, "ACCOUNTS", [])
    if not _is_seq(accounts) or not all(_is_seq(a) and len(a) == 7 for a in accounts):
        errors.append("ACCOUNTS must be a list of rows with 7 fields")
        accounts = []
    for label in ("PROJECT", "ACCOUNTS", "REQS", "TCS", "RESULTS", "ISSUES", "OQ"):
        _scan_illegal(getattr(d, label, None), label, errors)

    if errors:
        raise DataError(errors)
    return Checklist(project, list(accounts), reqs, tcs, results, issues, oq)
