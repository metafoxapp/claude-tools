"""Blank checklist data file. Copy it, fill it in, then build:

    python3 build_checklist.py data.py checklist.xlsx [open_questions.md]

Only load data files you trust: this file is executed as Python.
Placeholders in PROJECT are required (the builder rejects empty values); replace them.
"""

# Required text fields. scope_note and changelog are optional.
PROJECT = dict(
    name="<Product name>",                     # short product name, used in titles
    prefix="<PREFIX>",                         # TC ID prefix, e.g. "SHP" -> SHP-001, SHP-002 ...
    project="<Product / module under test>",   # shown on the Overview sheet
    version="<Checklist version / round>",     # e.g. "1.0 - first full checklist"
    sources="<Source documents and versions>", # PRD, user stories, ...
    test_site="<Test site URL (platform)>",
    scope_note="",                             # optional: what is out of scope
    changelog=[],                              # optional: list of ("YYYY-MM-DD", "what changed")
)

# Account testing rows, 7 fields each:
# (role, email, name, status, password_hint, scope_or_grant, notes)
# Never store real passwords; write a pointer such as "(see vault)".
ACCOUNTS = []

# Requirements, 5 fields each:
# (req_id, requirement text, epic, prd_reference, doc_status)
# req_id must be unique; TCS reference it.
REQS = []

# Test cases, 8 fields each. TC IDs are generated as <PREFIX>-001, -002 ... in list order.
# (req_id, epic, feature, scenario, steps, expected, type, priority)
#   req_id    must exist in REQS
#   steps     one string, steps separated by "|"
#   priority  one of: Critical, High, Medium, Low
TCS = []

# Results keyed by TC ID: {"<PREFIX>-001": (status, tester, notes)}
#   status    one of: PASS, FAIL, KNOWN GAP, BLOCKED, N/A, NOT TESTED
# TCs without an entry stay NOT TESTED.
RESULTS = {}

# Issue Log rows, 10 fields each (a plain string makes a section divider row):
# (ref, title, type, severity, req_id, tc_id, status, jira_key, found_in, notes)
#   status    one of: Pass, Fail, Open for coding, N/A
#   req_id / tc_id may be "" or must exist in REQS / TCS
ISSUES = []

# Open questions keyed by ID, e.g. "Q-<PREFIX>-01":
# dict(topic=..., kind="Conflict" | "Gap", priority="P0".."P3",
#      status="OPEN" | "CONFIRMED" | "RESOLVED (doc)" | "PARTIAL"   (optional, default OPEN),
#      tcs=[TC IDs or free text], options=[(label, source, text), ...],
#      site=..., question=..., docs_note=..., answer=...)
OQ = {}
