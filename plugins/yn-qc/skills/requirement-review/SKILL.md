---
name: requirement-review
description: Use when the user shares a PRD, spec or user story, or asks for requirement gaps, test scenarios, coverage, regression impact, test data, a permission matrix, a testing estimate or a release go/no-go, as analysis in the chat rather than checklist files or Jira tickets.
argument-hint: "[task, e.g. analyze requirement | P0 scenarios | release readiness] [document or text]"
---
# QC requirement review

Manual-testing analysis: read requirements, find what is confirmed and what is not, design the scenarios that matter, judge coverage, regression and release risk. The result is analysis in the chat; other skills turn it into files and tickets.

**Golden rule:** never infer a requirement. Every statement in your output carries one label from the table below, and anything that is not confirmed by a source is never written as if it were.

**Not this skill:**
- Building or updating the Checklist + RTM workbook or the Open Questions file → `/yn-qc:checklist-gen` (or `/yn-qc:checklist-import` for a whole document set).
- Writing, reviewing or classifying a Jira ticket → `/yn-qc:ticket-review`.
- Executing tests on a site → `/yn-qc:retest-run`; summarising an automated run → `/yn-qc:testrun-report`.

## Sources and language

- Read every document the user gives. When a decisions file or a confirmed answer exists it overrides the PRD; cite it.
- Cite the source of every confirmed item in brackets: `(PRD 3.1)`, `(US-2.4)`, `(DEC-12)`, `(Q-SHP-01 confirmed)`. No source → it is not confirmed.
- Write the analysis in the user's language. Write scenarios, steps and expected results in English, because they go into the checklist unchanged.

## Labels (one set, used everywhere)

| Label | Use when | Becomes |
|---|---|---|
| **Confirmed Requirement** | Stated in a document; cite it | A `REQS` row in checklist-gen |
| **Confirmed Rule** | Decided by the PO/BA outside the PRD (decision, answered question); cite it | The expected result of the linked scenarios |
| **Conflict** | Two sources disagree | Open question `kind="Conflict"`, both readings with their sources in `options` |
| **Gap** | Information needed to test is missing (rule, message, limit, UI state, design) | Open question `kind="Gap"` |
| **Assumption** | Your reasonable guess, not confirmed | Stated as such; scenarios that rely on it end with "(assumption)". If it changes an expected result, raise it as a Gap too |
| **Risk** | Something likely to break or costly if it breaks | Drives priority and regression scope |
| **Recommendation** | Your suggestion (extra check, doc fix, UX change) | Its own section, never mixed into requirements |

For every Conflict, Gap and Assumption state the **testing impact**: which scenarios are blocked or uncertain and what you would expect under each reading. Never pick a side in a Conflict yourself.

## Priority

| Priority | Checklist value | Criteria |
|---|---|---|
| **P0** | Critical | Main flow; money, payment, reward; login, auth, permission; create/update/delete of the core object; state transitions; data loss. Release gate: must PASS. |
| **P1** | High | Important alternate flows, validation of P0 inputs, integrations, high-traffic features. |
| **P2** | Medium | Secondary features, ordinary validation, UI states. |
| **P3** | Low | Cosmetic issues, rare edge cases. |

Raise one level when the area changed in this release or has a history of defects; lower one level when it is rarely used and has an easy workaround. Give a one-line reason for every P0 and for every change of level. Open questions use the same P0–P3 scale.

## Type and coverage angles

- **Type** (one per scenario, the checklist `Type` column): `Functional`, `UI`, `Permission`, `Integration`, `Regression`, `Exploratory`.
- **Angles** to consider for each requirement: happy path, alternate flow, negative, boundary, validation, permission, state transition, data consistency, integration failure, error handling, feature switched off.
- Techniques: equivalence partitioning, boundary values, decision table, state transition, use case, error guessing.
- Prefer coverage over count: one behaviour per scenario, no duplicates, test behaviour rather than UI implementation.

## Tasks

### 1. Requirement analysis
Extract objective, actors and roles, preconditions, functional requirements, business rules, validations, permissions, states, inputs/outputs, error handling, integrations, dependencies.

Output:
| # | Item | Label | Source | QC impact |
|---|---|---|---|---|

Then list the open questions ready for checklist-gen: `topic`, `question`, `kind` (Conflict / Gap), `priority` (P0–P3), affected scenarios, and for a Conflict each reading with its source.

### 2. Workflow analysis
Turn requirements into flows: main, alternate, error, state transition, cross-module. One line per step: `Input → Action → System processing → Output → Next state`, noting data created/updated, downstream impact and failure points.

### 3. Test scenario design
Output exactly the columns checklist-gen takes for `TCS`, so the rows can be pasted into the data file:

| Req ID | Epic | Feature | Scenario | Steps | Expected | Type | Priority |
|---|---|---|---|---|---|---|---|

- Scenario: one line, one behaviour. Steps: short, separated by `|`, starting from preconditions (role, setting, data).
- Expected: checkable; quote the exact message when the source gives one. Depends on an open question → append "(pending Q-…)". Depends on an assumption → append "(assumption)".
- Priority uses the checklist values (Critical / High / Medium / Low).
- Do not invent TC IDs; checklist-gen numbers them.

### 4. Coverage review
Map requirement → rule → scenario. When a checklist exists, start from its RTM sheet or the builder's `Reqs without TC` line. Look for requirements without a scenario, rules without a negative case, missing boundary / permission / state / integration cases, and duplicates.

| Req ID | Covered by | Coverage | Missing |
|---|---|---|---|

Coverage: Full / Partial / Missing.

### 5. Regression impact
For a fix or change:

| Area | Kind | Reason | Priority | Suggested tests |
|---|---|---|---|---|

Kind: Direct (changed code) / Related (shares the logic) / Cross-module (shares data, API, state) / Smoke (minimum after deploy). Propose a full regression only with a stated reason.

### 6. Exploratory charter
Mission, area, time box (e.g. 60 min), test ideas, risks, what to record. Always include: double click and duplicate submit, slow network, session expiry, concurrent edit, very long text, empty and large data sets, special characters and Unicode.

### 7. UI review
If a dedicated UI review skill is available (for example `ui-review` or `ui-ux-pro-max`), use it for the per-component detail. Otherwise compare with the approved design: layout and alignment, exact text and messages, loading / empty / error / disabled states, long text and overflow, the desktop viewports the project tests. Keep UI findings apart from business logic, and log a component-level defect once, not once per screen.

### 8. Release readiness
Inputs: Summary and RTM from the checklist, the latest retest round, open bugs and open questions. Verdict:
- **NO-GO** if any Critical scenario is FAIL, BLOCKED or NOT TESTED; any Critical/Blocker bug is open; or a P0 open question affecting an in-scope feature is unanswered.
- **GO WITH RISK** if every Critical scenario passes but High scenarios fail or open P1 questions remain; list each one with its workaround and owner.
- **GO** if every Critical and High scenario is PASS (or N/A / KNOWN GAP accepted by the PO) and no Major-or-worse bug is open.

Output: the verdict, the numbers (PASS / FAIL / BLOCKED / NOT TESTED by priority), then the reasons as bullets.

### 9. Testing estimate
Estimate from the scenarios, not from page count. Per area: count scenarios by priority; estimate design, execution, retest (based on the expected failure rate and number of rounds) and reporting; state every assumption (environment ready, test data, accounts, rounds); give a range (low–high), not a single number.

### 10. Supporting outputs
- **Test data:** valid, invalid, boundary, empty/null, duplicate, special characters, Unicode, long text, large and decimal numbers, dates (past, future, time zones), data owned by another account.
- **Permission matrix:** `| Role | View | Create | Edit | Delete | Approve |`; also check button visibility, direct URL, API authorisation, inherited permission, removed or inactive user, cross-owner access.
- **Integration cases:** success, invalid request, invalid response, timeout, retry, duplicate request, partial failure, data mismatch, auth failure.
- **QC status report:** Done / In progress / Blockers / Risks / Next, with numbers.
- **Teammate's test cases:** testable? expected clear? duplicates? missing negative / boundary / permission? priority right? behaviour or implementation detail? Answer with the row and the fix.

## Commands

Match the user's intent, in any language; the phrases are examples.

| Example request | Task |
|---|---|
| Analyze requirement / phân tích requirement / tìm gap | 1 |
| Main flows / luồng chính | 2 |
| P0/P1 scenarios / viết scenario | 3 |
| Review coverage / kiểm tra độ phủ | 4 |
| Regression impact / ảnh hưởng regression | 5 |
| Exploratory charter | 6 |
| Review UI | 7 |
| Release readiness / có release được không | 8 |
| Estimate / ước lượng effort | 9 |
| Test data, permission matrix, weekly report, review teammate's test cases | 10 |
| Create Jira bug / review ticket | → `/yn-qc:ticket-review` |

With no clear task: run task 1, then offer task 3 for the P0/P1 flows. Keep the output short and structured.

## Common mistakes

- Filling a missing message, limit or rule with what systems "usually" do. That is a Gap, not an expected result.
- Choosing one side of a Conflict and writing the scenario as if it were confirmed.
- Generating many near-identical scenarios instead of covering the missing angles.
- Proposing a full regression without saying why.
- Giving a release verdict without the numbers behind it.
