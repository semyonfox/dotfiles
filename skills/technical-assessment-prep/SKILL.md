---
name: technical-assessment-prep
description: "Use when prepare for timed technical recruiting assessments using invitation-grounded facts, language-aware drills, and small runnable practice repositories."
version: 1.0.0
created_by: agent

metadata:
  harness: [hermes]
---

# Technical assessment preparation

Use when Semyon needs to prepare for a timed coding, work-style, SDE, or similar recruitment assessment, especially when an invitation email provides constraints.

## Ground the format first

1. Read the relevant invitation email before recommending preparation.
2. Separate **verified invitation facts** from candidate reports or typical formats.
3. Report the confirmed role, invitation timestamp, deadline wording, duration, device/network requirements, requirement to complete all modules, accommodation contact, and any expressly stated proctoring/webcam/microphone rule.
4. Do not claim an exact question count, programming-language menu, section order, or monitoring policy unless the invitation or an official current source confirms it.
5. A unique assessment start link may begin the assessment. If the invitation says not to start until ready, do not open it merely to inspect the assessment structure.
6. If the wording is “within N days,” calculate a conservative working deadline with a time tool, show it in Ireland local time, and label it as an interpretation rather than an explicit expiry when appropriate.

## Match the practice language to the candidate

- Ask or infer Semyon’s strongest handwritten language before choosing drills.
- Do not default to Python purely because it is concise. If he is more comfortable with JavaScript and Java but rusty, use JavaScript for lower syntax/boilerplate overhead.
- If he is out of practice, treat it as a typing-and-pattern-recall problem, not a lack-of-ability problem. Use one small pattern at a time.

## Survival-prep loop

For a candidate who has mostly used AI, open-book coursework, IDE support, or non-general-purpose-code work recently:

1. Teach one pattern in plain English.
2. Trace a tiny example together.
3. Provide a minimal scaffold, not the completed answer.
4. Have him implement it and run a focused test command.
5. Read the actual file, explain the smallest failing point, and let him correct it.
6. Progress through: set/map lookup and counting; running totals; two pointers; sort then scan. Do not begin with a long generic LeetCode backlog.

### Conceptual alternatives

Treat familiar approaches as valid starting points. For character frequency counting, a 2D `[key, count]` table correctly represents the idea, but JavaScript `Map` is normally clearer and avoids repeatedly scanning that table for a key. Explain the trade-off rather than dismissing the simpler mental model.

## Minimal local practice repo

When Semyon wants live collaboration while practising:

1. Create a dedicated local repository rather than modifying an unrelated project.
2. Include one source file with a blank implementation, a small native test file, a minimal package/runtime config, and a README with the run command.
3. Run the tests once and verify their intentional failure is due to the blank function.
4. Keep the solution out of the starter file. After each attempt, inspect the changed file and run the tests before coaching.
5. Keep exercises narrowly scoped and build difficulty only after the current one works.

## Communication

- Be direct and calm. Do not imply a guaranteed pass or turn uncertainty into false certainty.
- Correct an earlier overstatement plainly if later evidence does not support it.
- Keep the immediate next exercise small enough that Semyon can complete it without a tutorial binge.
