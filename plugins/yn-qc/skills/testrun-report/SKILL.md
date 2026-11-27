---
name: testrun-report
description: Use when an automated test suite has to run (locally or in CI) and Claude should analyse only a short summary of the results instead of waiting through the whole run.
---
# Separate the test run from the agent session

Having the agent wait for a test suite is wasteful: most of the time is waiting, and the whole long log ends up in the context. Split it into two stages.

## Two stages

**The run stage** is handled by a script and needs no agent. The script belongs to the project (it depends on the test framework; this plugin does not ship one). It runs the suite with a JSON reporter, stores the results in `runs/<timestamp>/` and creates a `runs/latest` pointer. Turn off every reporter that calls the network in real time.

**The analysis stage** is the only one that needs the agent, and it reads only a summary file.

## The summary file

This is the key. `results.json` is usually dozens of times larger than what actually needs reading. The summary should contain only:

- One line with the pass / fail / flaky / skip totals
- Details **only** for failed and flaky cases: error message, location in the code, notes, screenshot path
- Skip reasons, grouped
- The list of passed case IDs, IDs only, nothing else
- Compared with the previous run: which cases newly fail, which pass again

The comparison with the previous run is the most valuable part, and the agent cannot work it out by itself because it never sees the earlier runs.

## Feeding the checklist

When the suite was generated from a QC checklist (`tcs.json`, see the checklist-gen skill), every test carries its TC ID (e.g. `SHP-004`). Then also write `summary.json` in this shape:

```json
{"results": [{"id": "SHP-004", "status": "failed", "message": "Expected total 50, got 20"}]}
```

`status` is one of `passed`, `failed`, `flaky`, `skipped`. The checklist-gen skill's `tcs_json.py results` turns it into the checklist's `RESULTS`, so the Excel, the RTM and the release numbers stay in step with the automated run.

## Re-run the failures

Let the script read the previous results and re-run only the failed and flaky cases. A retest round usually touches a few dozen cases out of a few hundred, so the difference is large.

## Push to the reporting system

If there is a central reporting server, push in batches **after** the run finishes; do not use a real-time reporter. A real-time reporter sends one request per test event; with a few hundred cases that is thousands of sequential requests, each taking up to a second when the server is far away.

When pushing in batches, keep each test's real timing rather than the import time, otherwise the duration charts will be wrong.

Always provide a dry-run mode that prints the tree it would send without sending it.

## Where to run

Run on the user's machine or in CI. The agent's cloud environment often gets in the way: a shared drive may not support symlinks, so the test runner cannot be installed. A script that only needs `node` still runs there.

## Do not measure by feel

When reporting an improvement, give the number you measured. If it has not been measured, say clearly that it is an estimate. File sizes are easy to compare; token savings can only be known by actually running a round.
