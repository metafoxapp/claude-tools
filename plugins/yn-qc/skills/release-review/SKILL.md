---
name: release-review
description: Use when the user asks whether a build can be released, what to regression-test after a fix or change, how much testing effort a scope needs, or for a QC status report, based on checklist results, bugs and open questions.
argument-hint: "[go/no-go | regression <change> | estimate <scope> | status report]"
---
# QC release review

Judge test progress and release risk from evidence: checklist results, the bug list, open questions and what changed. Every verdict comes with the numbers behind it.

**Not this skill:**
- Analysing a PRD, finding requirement gaps, designing scenarios or reviewing coverage → `/yn-qc:requirement-review`.
- Building the checklist or recording results → `/yn-qc:checklist-gen`; running a retest round → `/yn-qc:retest-run`.
- Writing or reviewing a Jira ticket → `/yn-qc:ticket-review`.

## Inputs

- Prefer the latest checklist: the **by-priority table** on its Summary sheet (or the per-priority lines checklist-gen's builder prints, e.g. `Critical: PASS 2, FAIL 1`), the RTM, the Issue Log and the Open Questions file. A freshly built workbook has uncalculated formulas, so read the builder's lines rather than the Summary cells in that case. Ask for them when missing instead of guessing numbers.
- State the date and round of the data you used. Never invent a count; when a number is unknown, say so and say what it would change.
- Write in the user's language.

## Shared scales

Defined in `/yn-qc:requirement-review` (the single source); in short:
- **Priority:** P0 = Critical (main flow, money, auth/permission, state, data loss; must PASS to release), P1 = High, P2 = Medium, P3 = Low.
- **Labels:** keep confirmed facts, Assumptions, Risks and Recommendations apart; never present an assumption as a fact.

## Tasks

### 1. Release readiness (go / no-go)
- **NO-GO** if any Critical scenario is FAIL, BLOCKED or NOT TESTED; any Critical/Blocker bug is open; or a P0 open question affecting an in-scope feature is unanswered.
- **GO WITH RISK** if every Critical scenario passes but High scenarios fail or open P1 questions remain; list each one with its workaround and owner.
- **GO** if every Critical and High scenario is PASS (or N/A / KNOWN GAP accepted by the PO) and no Major-or-worse bug is open.

Output:
```
Release recommendation: GO WITH RISK (checklist round 3, 27/11)
| Priority | PASS | FAIL | BLOCKED | NOT TESTED |
- Reason 1 (TC / bug / question ID)
- Reason 2
Risks accepted: …   Needed for GO: …
```

### 2. Regression impact
For a fix or change:

| Area | Kind | Reason | Priority | Suggested tests |
|---|---|---|---|---|

Kind: Direct (changed code) / Related (shares the logic) / Cross-module (shares data, API, state) / Smoke (minimum after deploy). Name existing TC IDs when a checklist exists. Propose a full regression only with a stated reason.

### 3. Testing estimate
Estimate from scenarios, not from page count. Per area: count scenarios by priority; estimate design, execution, retest (from the expected failure rate and number of rounds) and reporting; state every assumption (environment ready, test data, accounts, rounds); give a range (low–high), not a single number.

### 4. QC status report
Done / In progress / Blockers / Risks / Next, each line with numbers (scenarios run, PASS/FAIL, bugs opened/closed, questions open) and IDs. Short enough for a manager to read in a minute.

## Common mistakes

- A verdict without the numbers or the date of the data.
- GO while a Critical scenario is still NOT TESTED "because it probably works".
- Full regression proposed by default instead of the affected areas.
- A single-number estimate with hidden assumptions.
