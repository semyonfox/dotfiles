---
name: online-assessment-preparation
description: "Prepare for timed technical and work-style hiring assessments using the actual invitation requirements and focused, authentic practice."
version: 1.0.0
created_by: agent
related_skills:
  - personal-gmail
  - personal-coaching-workflows

metadata:
  harness: [hermes]
---

# Online assessment preparation

Use when Semyon asks to prepare for a timed hiring, internship, placement, coding, or work-style assessment, especially when the details are in an email invitation.

## Read the invitation first

1. Open the relevant invitation and reminder email thread using the personal Gmail workflow.
2. Extract: assessment name, role, invitation timestamp, stated completion window, device requirements, uninterrupted-duration guidance, completion confirmation, extension/contact instructions, and whether the start URL is unique.
3. Calculate the deadline from the **invitation timestamp plus the stated window**, then state it in Europe/Dublin time. Reminders may omit or obscure the deadline.
4. Never open a unique assessment-start URL simply to inspect its contents. Treat it as potentially starting or advancing the candidate's assessment.
5. State the hard logistics clearly: device, quiet room, reliable connection, charger, notifications off, and a longer reserved block than the vendor estimate.

## Coaching format

Be compact and interactive. Give the verified logistics, a role-specific high-yield plan, then one immediate mock exercise. Do not dump an exhaustive study syllabus unless Semyon explicitly requests one.

Keep preparation honest. Help Semyon articulate his own reasoning and values; do not coach him to fake a personality profile or attempt to exploit assessment mechanics.

## Amazon SDE assessment

For Amazon SDE/I internship invitations, prepare three areas:

1. **Coding:** high-yield patterns are hash maps/frequency counting, strings, sorting, two pointers/sliding window, stacks/queues, intervals, and basic graph/tree traversal. Use a small number of timed questions instead of unfocused grinding.
2. **Work-style or situational judgement:** map decisions to authentic Amazon-aligned behaviours: ownership, customer impact, data/evidence, proportional bias for action, early risk communication, durable fixes, high standards, and respectful disagreement followed by commitment.
3. **Possible SDE work simulation:** read prompts closely; prioritise customer/system impact, establish facts through logs/reproduction/data, communicate trade-offs, and distinguish immediate mitigation from root-cause prevention.

### Coding response checklist

```text
Clarify input, output, and constraints.
State a simple correct approach briefly.
Implement the efficient approach cleanly.
Test empty, singleton, duplicate, and boundary inputs.
Check time and space complexity.
Run one small manual test before submission.
```

### Work-style landmines

Avoid recommending behaviours that pass ownership away, hide problems, wait indefinitely for instruction, optimise a personal task over a high-impact shared issue, or make an uncommunicated risky production change. Do not encourage unnecessary perfection during an incident: mitigate safely, communicate, then drive root-cause follow-up.

## Suggested preparation cadence

- **Two days out:** 60–75 minutes of coding pattern refresh plus a short role/company-behaviour review.
- **One day out:** two timed coding questions and one short scenario discussion.
- **Assessment day:** no last-minute marathon. Confirm the environment, use a blank page for constraints and test cases, and reserve at least 15–30 minutes beyond the stated assessment time.

## Verification before finishing

- Is the deadline based on the original invitation rather than an assumption?
- Did the plan match the role and the actual assessment logistics?
- Are the recommendations short enough to be used today?
- Did the reply end with a concrete next exercise?
