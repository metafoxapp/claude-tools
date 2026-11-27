---
name: checklist-gen
description: Use when the team's QC Checklist + RTM workbook (Excel) or Open Questions file (Markdown) must be created or updated, including recording PASS/FAIL results, folding in a tester's hand edits or an automated run, and changing scope.
argument-hint: "[new <PRD> | results | scope-change]"
disable-model-invocation: true
allowed-tools: Bash(python3 *scripts/checklist/*)
---
# QC Checklist + RTM Builder

This skill packages the checklist format the team uses on real projects (hundreds of test cases, dozens of requirements and open questions) and the lessons learned while maintaining it over many test rounds. Use it together with `/yn-qc:requirement-review` (requirement analysis, scenario design, priority and Type values), `/yn-qc:ticket-review` (tickets) and `/yn-qc:release-review` (go/no-go from the numbers); this skill handles the **files**: data structure, build, result updates, delivery.

Paths used below:
- Scripts: `${CLAUDE_SKILL_DIR}/../../scripts/checklist/` (call it `$CK`). Needs Python 3 and `openpyxl`.
- Templates: `${CLAUDE_SKILL_DIR}/../../templates/checklist/` (call it `$TPL`): `empty_data.py` (blank data file), `example_data.py` (worked example for the fictional app "ShopLite"), `checklist-template.xlsx` (empty workbook), `open-questions.md` (Open Questions built from the example).
- Fill-in guide for testers (Vietnamese): `${CLAUDE_SKILL_DIR}/../../docs/checklist-guide.md`. Point users there when they ask how to fill the sheet.

If `${CLAUDE_SKILL_DIR}` is not set, find the `scripts/`, `templates/` and `docs/` folders two levels above this file (plugin install) or next to this file (claude.ai zip).

## Output files

1. `<Module>_QC_Checklist_RTM.xlsx` with 6 sheets:
   - **Overview**: project, document version, requirement sources, test site, list of sheets, how to use, scope note, status legend, priority legend, change log.
   - **Account testing**: test accounts per role (role, email, name, status, password pointer, scope/grant, notes).
   - **Checklist**: `TC ID | Req ID | Epic | Feature | Test Scenario | Test Steps | Expected Result | Type | Priority | Status | Tester | Notes / Ticket`. Status, Tester and Notes have a yellow header (the only columns testers fill). Dropdowns on Status and Priority, Status cells coloured by value.
   - **RTM**: one row per requirement: linked TCs, counts per status (COUNTIFS on Checklist), Coverage (COVERED / NO COVERAGE) and Requirement Result (PASS / PARTIAL / FAIL / KNOWN GAP / N/A / NOT TESTED / NO COVERAGE).
   - **Summary**: counts by TC status, by requirement result, and per epic with % Pass = PASS / (TC − N/A). All formulas.
   - **Issue Log**: defects found while testing (requirement questions go to the Open Questions file, not here): ref, title, type, severity, Req ID, TC ID, Status (Pass / Fail / Open for coding / N/A), Jira key, found in, notes.
2. `<Module>_Open_Questions.md`: the Vietnamese file sent to the PM: a header table (module, sources, sender, send date, desired answer deadline), how to answer, status meanings, a summary table, then each question under **A. Conflicts between documents** or **B. Missing or unclear**, with its options and sources, what the test site does, the question, a docs note and a line for the PM's answer.

Testers only fill Status, Tester and Notes; every other number updates itself because it is a formula. Formulas, dropdowns and colouring cover Checklist rows up to the last test case + 500. Do not let users append test cases by hand beyond that (or at all): add them to the data file and regenerate.

## Core principle: one data file is the source of truth

Never hand-edit a generated xlsx/md. All content lives in one `<module>_data.py` (in the scratchpad or the working folder); on every change → edit the data → run `build_checklist.py` → check → deliver. Reason: a checklist lives through many test rounds and many PRD changes; hand edits break formulas, IDs and RTM links, regeneration is always consistent.

The data file is executed as Python. Only build data files you or your team wrote; never one from an unknown source.

### Data file format

Start from `$TPL/empty_data.py` (blank, with comments) or copy `$TPL/example_data.py`. The builder (`$CK/qcdata.py`) validates exactly this (excerpt, one row per list; `$TPL/example_data.py` is a complete file that builds):

```python
# Required: name, prefix, project, version, sources, test_site. Optional: scope_note, changelog.
PROJECT = dict(name="ShopLite", prefix="SHP", project="ShopLite 1.0 - cart module",
               version="1.0 - first checklist",
               sources="shoplite-prd.md (v1.0) | shoplite-user-stories.md (v1.0)",
               test_site="https://shoplite.example.test (desktop web)",
               scope_note="Native mobile apps are out of scope for v1 (N/A).",
               changelog=[("2026-01-10", "First release of the checklist.")])

# (role, email, name, status, password_hint, scope_or_grant, notes) - never a real password, write "(see vault)"
ACCOUNTS = [("Customer", "linh@shoplite.example.test", "Linh", "active", "(see vault)", "Storefront", "")]

# (req_id, requirement text, epic, prd_reference, doc_status) - req_id unique
REQS = [("US-1.1", "As a shopper I can add a product to my cart", "Epic 1 - Cart", "PRD 3.1", "Implemented per doc")]

# (req_id, epic, feature, scenario, steps, expected, type, priority)
#   steps "step 1|step 2|step 3"; priority Critical | High | Medium | Low
TCS = [("US-1.1", "Epic 1 - Cart", "Add to cart", "Add an in-stock product",
        "Open a product page|Click Add to cart", "Cart badge shows 1 and the item is listed", "Functional", "Critical")]

# tc_id -> (status, tester, notes); status PASS | FAIL | KNOWN GAP | BLOCKED | N/A | NOT TESTED
RESULTS = {"SHP-001": ("PASS", "Linh (staging 12/01/2026, Linh – customer)", "Order #24 created.")}

# (ref, title, type, severity, req_id, tc_id, status, jira_key, found_in, notes); a plain string is a divider row
#   status Pass | Fail | Open for coding | N/A; req_id / tc_id may be "" or must exist
ISSUES = ["-- Smoke test round 1 --",
          ("SHP-BUG-01", "[Cart] Adding the same product twice creates a duplicate row", "Bug", "Major",
           "US-1.1", "SHP-002", "Open for coding", "", "Smoke 2026-01-12", "")]

# Open questions. Required: topic, question, kind (Conflict | Gap), priority (P0..P3).
#   status OPEN | CONFIRMED | RESOLVED (doc) | PARTIAL (default OPEN)
#   tcs: TC IDs (must exist) or free text such as "(no test case yet)"
#   options: [(label, source, text), ...] - the competing readings and where each comes from
OQ = {"Q-SHP-01": dict(topic="Guest checkout allowed", kind="Conflict", priority="P0", status="OPEN",
                       tcs=["SHP-004"], options=[("A", "PRD 4", "Guests can check out."),
                                                 ("B", "US-2.1", "Login is required to check out.")],
                       site="The test site lets guests check out.",       # what QC saw on the test site
                       question="Which option is correct for v1?",
                       docs_note="Align PRD 4 and US-2.1 once confirmed.",
                       answer="")}
```

TC ID = `<prefix>-<NNN>` (e.g. SHP-004), generated from the **position** in `TCS`. `ACCOUNTS`, `RESULTS`, `ISSUES` and `OQ` are optional.

## Procedures

### A. Create from a PRD
For a whole document set (PRD + decisions + permission rules + design), or to resync when those documents change, use `/yn-qc:checklist-import`; it writes the same data file. For a single PRD:
1. Read the whole PRD (and the mobile PRD if there is one). Split requirements per epic/section → `REQS`, each with its PRD reference for traceability and a doc status. Prefer one row per testable rule: `Reqs without TC` is checked per row, so a row that bundles five rules looks covered once any one of them has a test case.
2. Design test cases following `/yn-qc:requirement-review` (happy / negative / boundary / permission / state / integration / feature switched off / regression). Writing conventions:
   - Scenario: one behaviour per test case, one line ("Verify …" or a short action such as "Add the same product twice").
   - Steps short, separated by `|`, starting from the preconditions (setting, role, data).
   - Expected must be checkable; quote the exact message when the PRD has one; join several results with ";".
   - Priority and Type: use the criteria and values defined in `/yn-qc:requirement-review` (Critical = release gate, must PASS to release).
   - Mobile test cases go last in their epic, scenario ending "… on mobile".
3. Where the PRD is ambiguous or contradicts itself → create an OQ and list the affected TCs in its `tcs` (and mention it in the expected, e.g. "(pending Q-SHP-01)") instead of guessing the expected result. `kind="Conflict"` when sources of equal standing disagree (list each side in `options` with its source), `kind="Gap"` when information is missing. A decision that overrides the PRD is not a Conflict: write the expected result from the decision and cite it. IDs: `Q-<PREFIX>-NN` (e.g. `Q-SHP-01`) in every skill of this plugin. Never reuse an ID.
4. Fill `ACCOUNTS` with one row per role you test with.
5. Build, check, deliver (sections D, F).

### B. Update test results
1. **Get the user's latest copy first** – users often edit the checklist directly. If the file is on the user's machine: compare mtime, stage the new copy, run `python3 "$CK/diff_user_edits.py" <user_copy.xlsx> <data.py>`. It prints one line per changed TC (`SHP-002: NOT TESTED -> FAIL`), `NOTE:` lines (e.g. a TC missing from the sheet, whose existing result is kept), and a complete, paste-ready `RESULTS = {...}` block with the user's values; replace `RESULTS` in the data file with it. The user's values win; if your own evidence contradicts them (e.g. you just saw FAIL but the user set PASS), keep the user's value and say so in the reply, never overwrite silently.
2. **Before rebuilding, ask the user whether they also changed the Issue Log or Account testing sheets** (the guide tells testers to send those changes to the QC lead, but they may have edited the file anyway). The builder regenerates every sheet from the data file, so any such edit is lost unless you fold it into `ISSUES` / `ACCOUNTS` first. `diff_user_edits.py` reads only Status / Tester / Notes of Checklist.
3. Record results following the rules in "Recording results".
4. Build → check → deliver. In the reply give: totals PASS / FAIL / NOT TESTED (and KNOWN GAP / BLOCKED when present), the TCs whose status changed, partial TCs and what is still missing.

### C. PRD change / new scope
- Append new TCs at the **end** of `TCS` so existing IDs do not change (IDs already live in tickets, notes, open questions). Never insert in the middle, never delete: a TC dropped from scope → status N/A + a note with the reason.
- New requirement → add to `REQS`; the builder reports requirements without a TC.
- A question gets confirmed → set its `status` and `answer`, add a dated entry to `PROJECT.changelog`, update `version`; update the expected result of the linked TCs if the rule changed.

### D. Build & check
```bash
python3 "$CK/build_checklist.py" <module>_data.py <Module>_QC_Checklist_RTM.xlsx <Module>_Open_Questions.md
```
The third argument is optional (omit it to build only the workbook). On success the script prints the TC and requirement counts, the status counts, one line per priority (e.g. `Critical: PASS 2, FAIL 1`, what `/yn-qc:release-review` needs for the release gate) and `Reqs without TC: ...`; use these numbers for the report. On bad data it writes nothing, prints one `ERROR: ...` line per problem and exits 2: unknown Req ID / TC ID, duplicate Req ID, wrong field count, a priority or status outside the allowed values, a missing required PROJECT or OQ field, PASS or FAIL on a test case whose expected result is still "(pending Q-…)" (use BLOCKED until the question is answered). Fix every error, then build again.

After building, compare the status counts with the previous build to make sure no TC changed by accident. If an xlsx skill with a formula recalculation script (LibreOffice) is available, recalculate and confirm 0 formula errors; openpyxl alone does not compute formula values, so do not read Summary numbers back with `data_only` from a freshly built file.

### E. Automated runs (tcs.json)
The automated suite reads `tcs.json`; never write it by hand:
```bash
python3 "$CK/tcs_json.py" export <module>_data.py tcs.json
```
One entry per test case (`id`, `req_id`, `epic`, `feature`, `title`, `steps`, `expected`, `type`, `priority`), same IDs and order as the Checklist sheet. Tests must be named or tagged with the `id`. Re-export after every change to `TCS`.

After a run (see `/yn-qc:testrun-report`), fold its summary back into the data file:
```bash
python3 "$CK/tcs_json.py" results <module>_data.py summary.json --tester "CI run <n> (<env> dd/mm/yyyy)"
```
`summary.json` is `{"results": [{"id": "SHP-001", "status": "passed|failed|flaky|skipped", "message": "…"}]}`. The script prints the changed TCs and a complete `RESULTS = {...}` block to paste in: passed → PASS, failed → FAIL, flaky → NOT TESTED with note "Flaky…", skipped → unchanged, and a pending test case stays BLOCKED. Then build (section D).

### F. Deliver
Send the files to the user; if there is a folder on the user's machine, overwrite there with an mtime check (the file has not been edited since you staged it). Short reply: numbers, changed TCs, points the user needs to decide.

## Recording results (Status / Tester / Notes columns)

- **Status**: PASS, FAIL, KNOWN GAP, BLOCKED, N/A, NOT TESTED.
  - Partially tested → keep **NOT TESTED**, note starts with "Partial – " + what was checked + what is missing. Never mark PASS before every expected point is met.
  - Behaviour matches a rule the PM has confirmed (even if it differs from the PRD) → **PASS**, note cites the question ID (e.g. "Rule confirmed (Q-SHP-01, 30/10/2026): …"). Do not use N/A for this case – users have turned such N/A values back into PASS.
  - **KNOWN GAP**: the behaviour is missing but documented as a known gap / not built (the requirement's doc status says so). Note cites the source.
  - **BLOCKED**: cannot be tested until another issue is fixed, or the environment prevented the test (data left over, network down); note says what blocks it.
  - N/A only when the TC was taken out of scope by a decision.
  - FAIL: note describes the symptom + "Ticket logged." once logged (and the Issue Log row / ticket key). Retest: "[Retest dd/mm] …" and change the status to the new result.
  - The user confirms verbally ("mobile cases passed") → record PASS, tester "<Name> (…, confirmed dd/mm/yyyy)", and in the reply list separately the TCs that went from FAIL to PASS so the user can double-check.
- **Tester**: `<Name> (<env> dd/mm/yyyy, <account> – <role>, <platform if not web>)`, e.g. `Linh (staging 30/10/2026, Linh – customer)`.
- **Notes** (English, specific, verifiable): data IDs (order #24, product 1458, coupon #148), exact messages in parentheses, numbers before/after, settings changed and restored. Do not speculate about causes. When the user says a point "is not a bug" → remove that remark from the note entirely, do not leave "Minor: …".

## Lessons learned on projects

- Never guess IDs: TC / Req / OQ IDs must come from the data; the builder validates them. (A wrong TC ID once ended up in a PRD-vs-code comparison table.)
- Do not let a confirmed question keep TCs blocked: once an OQ is CONFIRMED or RESOLVED (doc), update the expected results, clear "(pending …)" and retest. The RTM Requirement Result only reaches PASS when every linked TC is PASS or N/A.
- Open questions go to the PM in Vietnamese (the Open Questions .md), while the checklist itself stays in English. Evidence from the test site (`site`) helps the PM answer faster.
- `PROJECT.changelog` is the change log shown on Overview and dates the Open Questions file: each time you add or confirm a question or change scope, add a dated entry.
- Never hard-code numbers in the file: every total is a formula, so when the user edits Status in Excel, Summary and RTM stay right.
- Keep the data file in the scratchpad for the whole project; when a new session starts and the scratchpad is gone, rebuild the data from the user's latest files (Checklist, RTM, Account testing and Issue Log restore `REQS` / `TCS` / `RESULTS` / `ACCOUNTS` / `ISSUES`; the Open Questions .md restores `OQ`) before editing further.
