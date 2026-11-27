---
name: retest-run
description: Run a retest round or a full run on staging using Playwright through the UI only, then update the checklist and write tickets for the failures.
argument-hint: "[round name] [scope, e.g. failed+blocked+not-tested]"
disable-model-invocation: true
---
# Run a UI-only retest round

One round is: choose the cases to run, run them through the real UI, update the checklist, write tickets for the failed cases.

This skill needs the checklist-gen skill (on claude.ai, upload both skills). The checklist is the one it builds (same template, same data file); its scripts, data format and recording rules are used as written there. Record results in its data file and regenerate; do not edit the workbook by hand.

## What UI-only means

Test like an end user: act only through the interface, never call an API to set up data or to verify a result. If a case can **only** be checked through an API (e.g. verifying an audit record), mark it BLOCKED with the reason; do not slip over to the API and then record PASS — that result does not reflect what the user experiences.

Exceptions must be stated by the requester, case by case.

## Before running

Back up the checklist and the ticket file with a timestamp suffix (`*.before-<task>-<date>.xlsx`). Back up on every round, because accidental overwrites happen often.

If the user may have edited the checklist since the last build, pull their changes into the data file first (`diff_user_edits.py`, see section B of the checklist-gen skill).

Choose the scope: usually the FAIL, BLOCKED and NOT TESTED cases of the previous round, plus new cases. State the scope before running so the reader knows what the final numbers include.

## While running

Take a screenshot as evidence for every failed case, saved under `tickets/evidence/<round-name>-<date>/`. A case that passes again after having failed should also get a screenshot, because someone will ask.

Write down the data you created on staging: order numbers, coupon codes, accounts used. The next round will need to know which data is yours.

When a case fails because of the environment and not because of a product defect (network lost, data left over from a previous round), record BLOCKED with the reason instead of FAIL.

Record each result with the Status / Tester / Notes rules of the checklist-gen skill ("Recording results"), e.g. tester `Linh (staging 12/01/2026, Linh – customer)`, note "Retest 12/01: …".

## Writing tickets

One defect, one ticket, numbered on from the existing file, never restarting from 1 (in the checklist data these are `ISSUES` rows, e.g. `SHP-BUG-07` after `SHP-BUG-06`). Each ticket has: a title naming the module and screen, the account to reproduce with, the steps, the actual result, the expected result with its source (decision number or PRD section), and the screenshot path. Use `/yn-qc:ticket-review` for the wording.

Pure UI or experience issues are presented in the conversation; do not add them to the ticket file yourself unless asked.

When the expected result in the checklist is wrong compared with the documents, fix the expected result and close the ticket as "Not a bug" (Issue Log status N/A, note "Not a bug"), do not leave the case hanging at FAIL.

## Reporting back

One summary line: total PASS / FAIL / BLOCKED (and KNOWN GAP when present) after this round. Then list the cases that changed status and the new tickets. Do not narrate every case that was run.

State clearly which checklist file is the canonical one after the round, and whether the snapshot in the source of truth has been updated to match.
