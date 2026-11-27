---
name: checklist-import
description: Use when a QC checklist (RTM) must be built from a set of source documents (PRD, decisions, permission rules, UI design), or resynced after those documents change, as an Excel file plus a tcs.json for automated tests.
argument-hint: "<folder or files with the source documents>"
disable-model-invocation: true
---
# Build a QC checklist from source documents

Turn requirement documents into a traceable set of test cases (RTM): Excel for people to read and `tcs.json` for the automated test suite.

The file part (data format, build, results, delivery) is the checklist-gen skill (on claude.ai, upload both skills): write the test cases into its data file (start from `${CLAUDE_SKILL_DIR}/../../templates/checklist/empty_data.py`) and build the workbook with `${CLAUDE_SKILL_DIR}/../../scripts/checklist/build_checklist.py`, so the Excel uses the same template as every other checklist. This skill covers turning the documents into that data. Labels, priority criteria and Type values come from `/yn-qc:requirement-review`; use its analysis when one exists instead of redoing it.

If `${CLAUDE_SKILL_DIR}` is not set, find the `scripts/` and `templates/` folders two levels above this file (plugin install) or next to this file (claude.ai zip).

## Before you start

Pin the **source of truth**: copy the documents from the repo into a separate folder with a `SOURCE.md` that records the commit hash and the date they were taken. All later analysis works on this copy, not on the repo, which keeps changing. When the documents are refreshed, keep the old copy in `backup/<commit>/` so you can compare what changed. Record the sources and their versions in `PROJECT.sources`.

Read in this order: PRD → decisions → permission rules → UI design → repo impact. The decisions file **overrides** the PRD: when the two disagree the decision wins, it is not a Conflict, and the decision number (e.g. DEC-12) must be written into the expected result. Add a docs note that the PRD needs updating.

## Generate test cases

Split by module, one stable code per module, for example for ShopLite: PER = permissions, CRT = cart, CHK = checkout, PAY = payment, ADM = admin dashboard, E2E = end to end. The builder numbers TCs as `<prefix>-<NNN>` by position, so give each module its own data file with a prefix such as `SHP-CRT` (giving SHP-CRT-001, SHP-CRT-002 …), or use one prefix and keep each module in its own epic. An ID once issued is **never reused** for another case, even when the old case is dropped — mark it deprecated (status N/A, note "Deprecated – <reason>", row kept) instead of deleting it, because the ID already appears in tickets and old reports. New cases are appended at the end.

Each case needs: requirement (`req_id`), epic/milestone, feature, scenario (one line, used as the test name), steps, expected, type, priority (Critical / High / Medium / Low, criteria in requirement-review).

Give each testable rule its own `REQS` row (e.g. `PRD-5.2a` cap, `PRD-5.2b` expiry): the builder's `Reqs without TC` is checked per row, so a row that bundles several rules looks covered when only one of them is.

Write the expected result so it can be verified. "Displays correctly" is useless; "Orders and Products: view only; Refunds: not allowed" is usable. When the expected result comes from a decision, quote its number in it.

## When documents contradict each other

This applies to sources of equal standing (PRD vs user story, PRD vs design, two decisions); a decision over the PRD is handled above. Do not pick a side yourself. Record it as an open question with ID `Q-<PREFIX>-NN` (`kind="Conflict"`), giving both readings and the source of each (`options`), list the affected cases in its `tcs`, and leave those cases waiting for PO confirmation (expected marked "(pending Q-…)", not PASS or FAIL). When the answer comes, update the expected results and mark the question CONFIRMED. Missing information (nothing to contradict, just not specified) is `kind="Gap"`.

## Sync when the documents change

Compare the new copy with the backup and classify every change: new case to add, case whose expected must change, case that becomes deprecated. Report it with concrete numbers ("18 new TCs, 12 TCs with updated expected results, 1 TC deprecated"), never in general terms. Add a dated entry to `PROJECT.changelog` and update `PROJECT.version`.

Write `tcs.json` with `python3 ${CLAUDE_SKILL_DIR}/../../scripts/checklist/tcs_json.py export <data.py> tcs.json` after every sync (format: section E of the checklist-gen skill), never by hand, so it always matches the Excel.

## Before reporting done

Self-check: every requirement in the documents is covered by at least one case (the builder prints `Reqs without TC`); no duplicate IDs; every expected result can be verified by an action; every contradiction has become an open question instead of being silently decided.
