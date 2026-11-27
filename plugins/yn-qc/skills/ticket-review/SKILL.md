---
name: ticket-review
description: Review, improve, classify and draft QA/QC Jira tickets for bugs and improvements, used when the user asks to write, review, shorten or refine Jira titles, reproduction steps, actual/expected results, severity, references, evidence or developer comments.
argument-hint: "[adjust title | review | shorten | log bug | log improvement | improve comment] <ticket text>"
---
# QC Skill: Review & Log Jira Tickets

## 1. Purpose

Help QC engineers create clear, reproducible, developer-ready Jira tickets. Preserve observed facts. Use **English** for ticket content; use the user's language (Vietnamese for the team this was written for) for explanations. If asked only to adjust a title or comment, return only that — do not expand into a full ticket.

For whether an expected behaviour is actually confirmed (requirement gaps, open questions), see `/yn-qc:requirement-review`.

## 2. Core principles

Use these four principles as the default ticket-writing standard:

1.  **Title to identify** --- The title lets developers identify the
    affected feature and symptom immediately.
2.  **Steps to reproduce** --- The steps allow developers to reproduce
    the issue.
3.  **Actual to prove** --- The actual result states what QC observed.
4.  **Expected to define done** --- The expected result defines the
    correct behavior after the fix.

## 3. Bug vs. Improvement classification

Do not classify an issue based only on whether code changes are
required.

### Bug

Classify as **Bug** when the current implementation does not match a
confirmed expectation, such as:
- PRD, FRS, user story, acceptance criteria, or approved design.
- A previously confirmed behavior that has regressed.
- A platform or feature parity requirement.
- An established business rule or permission rule.

Examples:
- An age-restricted product photo is displayed without the required blur or warning.
- A button label has unexpectedly changed from the approved text to an incorrect label.
- A product row cannot be scrolled with the mouse wheel even though the PRD explicitly requires mouse-wheel scrolling.
- Seller contact information is not displayed to a buyer who has the required `can_view_seller_contact` permission.
- The checkout flow freezes and prevents the user from placing an order.

### Improvement

Classify as **Improvement** when the user proposes a new capability or
usability/performance enhancement that is not already required by an
approved specification.

Examples:
- Allow users to type a product quantity manually instead of using only `+` and `-` controls, if manual entry is not already required.
- Improve handling/loading performance for large product image uploads when the current behavior meets the configured upload-size rule and no performance requirement has been violated.

### Clarification required

Do not log a Bug based on an assumption when:
- The requirement is ambiguous or incomplete.
- The expected behavior has not been confirmed.
- The behavior may be intentional.
- Different documents or stakeholders provide conflicting expectations.

In such cases, state that requirement clarification is needed. Do not
invent the expected behavior.

### Classification decision rule

Ask:

1.  Is the expected behavior explicitly defined or previously approved?
2.  Does the observed behavior violate that expectation?

If both answers are **Yes**, classify as **Bug**.

If the requested behavior is new and not required by the current
specification, classify as **Improvement**.

If the expected behavior cannot be established, classify as
**Clarification Required** or ask one focused question.

## 4. Writing the Jira title

### Recommended format

Use:

`[Module][Platform][Area] + concise issue symptom`

(Module = the feature; Platform = Web / iOS / Android or a sub-module; Area = the screen or component.)
Include only the tags that help identify the issue. Do not force every
ticket to use all tag levels.

Examples:
- `[Checkout][Android][Payment] "ShopLite isn't responding" is shown on Samsung Galaxy S23`
- `[Wishlist] Age-restricted product photo is displayed without blur or warning`
- `[Product Editor] Error occurs when adding or deleting table columns`
- `[Product Detail] Seller contact information is not displayed to permitted viewers`
- `[Cart] Support manual quantity input for products`

### Title rules

-   Describe the **observable symptom**, not an unconfirmed root cause.
-   Be specific about the feature, platform, device, screen, or
    component when relevant.
-   Prefer concise wording and remove repeated ideas.
-   Use natural, grammatically correct English.
-   Use consistent terms from the product UI and requirement documents.
-   Include device details when the issue is device-specific.
-   Avoid vague titles such as `Feature not working`, `Layout issue`, or
    `Please check`.
-   Do not put long reproduction details or expected behavior into the
    title.
-   For a regression, mention the incorrect current behavior; add
    `regression` only when it helps triage.

### Useful symptom wording

-   `is not displayed`
-   `is displayed without ...`
-   `cannot be scrolled`
-   `cannot be saved`
-   `requires tapping twice`
-   `freezes when ...`
-   `remains stuck at ...`
-   `is cut off`
-   `overlaps ...`
-   `does not respond to ...`
-   `shows incorrect text`

## 5. Steps to Reproduce

### Recommended format

**Steps to Reproduce:**
1. Log in as `[role/user type]`, if relevant.
2. Navigate to `[feature/screen]`.
3. Perform `[specific action]`.
4. Observe `[result/location]`.

### Rules

-   Include only steps needed to reproduce the issue.
-   State the required user role or permission when it affects the
    behavior.
-   Include necessary preconditions and test data.
-   Mention relevant configuration or feature settings.
-   Include platform, device, browser, and environment when relevant.
-   Use concrete data when it helps reproduce the issue, such as an
    order containing 4--5 products.
-   Avoid irrelevant navigation details and repeated instructions.
-   Do not remove a step if it is essential to reproduce the issue.

For a simple issue, 2--4 steps are usually sufficient. This is a
guideline, not a strict limit.

## 6. Actual Result

Actual Result must describe what QC directly observed.

### Rules

-   Be factual, concise, and specific.
-   State the visible behavior, error, missing content, or failed
    action.
-   Do not speculate about root cause.
-   Do not describe an unverified backend state.
-   Do not claim a system message is displayed by the app if it is
    actually an operating-system dialog.
-   Do not include placeholder text or unverified outcomes.
-   Avoid repeating all Steps to Reproduce.

*(Attribute OS dialogs correctly: "Android displays \"ShopLite isn't responding\"" — not "the app displays".)*

## 7. Expected Result

Expected Result must describe the behavior that should happen, based on
a confirmed source.

### Rules

-   Use the PRD, FRS, user story, acceptance criteria, approved design,
    or confirmed existing behavior.
-   Keep it concise and testable.
-   State the required outcome, including permission or configuration
    conditions.
-   Do not add new requirements that are not supported by the source.
-   Avoid vague wording such as `should work properly`.
-   Do not repeat the full issue description.

Preserve exact permission conditions: `can_view_seller_contact` → do not broaden to "visible to all users."

## 8. Preconditions and Environment

Include these sections only when relevant.

### Preconditions

Use for setup conditions needed before reproduction, such as:
- User is logged in.
- Required permission is granted.
- A product, order, coupon, or listing has already been created.
- A feature setting is enabled.
- Camera and microphone permissions are granted.

### Environment

Include relevant details:
- Platform: Web / iOS / Android.
- Device and model.
- OS version.
- Browser and version.
- App version/build.
- Environment: Dev / Staging / Production.
- Network type, if relevant.

For device-specific issues, list which devices FAIL vs PASS. Do not invent device models, OS versions, or build numbers.

## 9. Evidence and References

- **Evidence** = what happened (screenshot, recording, log)
- **Reference** = what should happen (PRD/story/design — specific section or ID)

Do not fabricate references. If none available, state that expected behavior needs confirmation.

## 10. Severity and Priority

Recommend severity based on user and business impact, not on how
visually noticeable the issue is.

General guidance:
- **Critical / Blocker:** Core system or critical business flow is unusable, or there is severe widespread impact.
- **Major:** An important feature or flow is blocked for affected users, with no reasonable workaround.
- **Minor:** Limited impact, cosmetic issue, or a secondary action is affected while the main flow remains usable.

These are general guidelines. Follow the project's own severity and
priority definitions when available.

Do not assign a severity if the impact is unclear. Explain the reason
briefly when making a recommendation.

## 11. Jira comments for developers

Comments should be short, polite, and action-oriented.

### Comment rules

-   State the current status or remaining issue.
-   Clearly request the next action.
-   Avoid unnecessary background already documented in the ticket.
-   Do not use ungrammatical wording such as `does not shown`.
-   Use `still` when confirming that the issue remains after a fix or
    retest.
-   Do not claim that testing passed or failed unless the user provided
    that result.

## 12. Shortening and reviewing an existing ticket

When the user provides an existing ticket for review:

1.  Preserve all verified facts and important reproduction conditions.
2.  Remove repetition and unnecessary narrative.
3.  Improve grammar and natural technical wording.
4.  Keep the structure appropriate to the issue.
5.  Do not add sections the user does not need.
6.  Flag missing information only when it materially affects
    reproduction, classification, or expected behavior.
7.  Return a polished, ready-to-paste version.

If the user asks only to review a title, revise only the title and
briefly explain the change if useful.

If the user asks only to improve a Jira comment, return only the
improved comment.

## 13. Avoid unverified information and placeholders

Never invent:
- Root cause.
- API/backend behavior.
- Database state.
- Server-side record creation or status.
- Result after tapping `Wait`, `Close app`, or another action unless observed.
- Device model, OS version, app version, or browser version.
- Requirement IDs or source references.
- Permission rules or business logic.

If a detail is unknown:
- Omit it if not essential.
- Ask one focused question if it is essential.
- Mark it as `Not verified` only when that distinction is useful.
- Do not leave drafting placeholders such as `<add result>` in a final ticket unless the user explicitly asks for a template.

## 14. Ready-to-use Jira templates

### A. Bug ticket

**Title:** `[Module][Platform][Area] [Observed issue]`

**Preconditions:**\
- `[Required setup, role, permission, or configuration]`

**Steps to Reproduce:**
1. `[Step 1]`
2. `[Step 2]`
3. `[Step 3]`

**Actual Result:**\
`[What QC directly observed.]`

**Expected Result:**\
`[Confirmed expected behavior.]`

**Environment:**\
- Platform/device: `[Known details]`
- App/browser version: `[Known details, if relevant]`

**Evidence:**\
`[Screenshot/video/log, if available]`

**Reference:**\
`[PRD/Story/Design section, if available]`

### B. Improvement ticket

**Title:**
`[Module][Area] Support / Improve [requested capability]`

**Description:**\
`[Current behavior and why it is inconvenient or insufficient.]`

**Expected Improvement:**\
`[Requested new or improved behavior.]`

**Acceptance Criteria:**
- `[Testable criterion 1]`
- `[Testable criterion 2]`
- `[Compatibility or regression criterion]`

### C. UI issue

**Title:** `[Module][Area] [Visual symptom]`

**Steps to Reproduce:**
1. `[Navigate to the screen]`
2. `[Trigger or observe the UI state]`

**Actual Result:**\
`[Describe the incorrect layout, text, alignment, clipping, overlap, or state.]`

**Expected Result:**\
`[Describe the intended UI behavior, grounded in design or confirmed existing behavior.]`

**Evidence:**\
`[Screenshot or recording]`

### D. Developer comment

`[Current issue/status]. Please [specific requested action].`

## 15. Key examples

### Bug — permission
**Title:** `[Product Detail] Seller contact information is not displayed to permitted viewers`
**Steps:** 1. Seller adds contact info. 2. Log in as a buyer with `can_view_seller_contact`. 3. Open the product detail page.
**Actual:** Contact information is not displayed.
**Expected:** Contact information should be displayed to users with `can_view_seller_contact` permission.
**Reference:** US-1.3

### Bug — system dialog attribution
**Title:** `[Checkout][Android][Payment] "ShopLite isn't responding" is shown on Samsung Galaxy S23`
**Actual:** The order cannot be paid. Android displays **"ShopLite isn't responding"** (Close app / Wait).
**Expected:** Payment should complete successfully on Samsung Galaxy S23.
*(Attribution: Android shows the dialog, not the app.)*

### Bug — requirement violation vs. Improvement
**Title:** `[Home][Web][Product Row] Mouse-wheel scrolling does not move the product row`
**Actual:** Scrolling the mouse wheel over the product row does not move it.
**Expected:** Row should scroll sideways on mouse-wheel input without changing the page.
*(If PRD explicitly requires mouse-wheel scrolling → Bug, not Improvement.)*

### Improvement
**Title:** `[Cart] Support manual quantity input for products`
**Description:** Users can only use `+` / `−`; cannot type a quantity directly.
**Expected Improvement:** Allow typing quantity while keeping `+` / `−` controls.
**Acceptance Criteria:** Valid positive integers only. Respects stock limits. Existing controls still work.

## 16. Pre-submission checklist

- [ ] Title: feature + symptom; no root cause
- [ ] Bug / Improvement / Clarification correctly classified; severity set
- [ ] Steps reproducible; role/permission included when needed
- [ ] Actual = observed facts only; Expected = confirmed source
- [ ] No invented details, placeholders, or unresolved items
- [ ] Evidence attached; reference cited when available
- [ ] Concise and ready for developer handoff

## 17. Default AI response behavior

When handling QC Jira requests:

-   **"Adjust title"** → Return an improved title only.
-   **"Review ticket"** → Return a polished ticket and mention only
    important corrections.
-   **"Shorten ticket"** → Remove repetition while preserving
    reproduction-critical details.
-   **"Log bug"** → Draft a complete Bug ticket using the known facts.
-   **"Log improvement"** → Draft an Improvement with current behavior,
    requested improvement, and testable acceptance criteria.
-   **"Bug or Improvement?"** → Explain the classification based on
    confirmed requirements.
-   **"Improve comment"** → Return a concise developer-facing comment.
-   **Missing critical information** → Ask one focused question; do not
    create a long questionnaire.
-   **User says not to access a link** → Do not open or investigate it;
    work only with the supplied text.
