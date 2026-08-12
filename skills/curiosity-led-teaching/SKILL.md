---
name: curiosity-led-teaching
description: "Teach Semyon technical or academic material through bounded curiosity, active prediction, real-project relevance, and visible closure."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]

metadata:
  harness: [hermes]
---

# Curiosity-led teaching

Use when Semyon asks to learn, revise, understand, practise, or get motivated for a topic. This is an engagement method, not a retention hack: create a **specific, solvable information gap**, then resolve it clearly and turn it into usable skill.

## Governing model

Curiosity works best when the learner can see the shape of a missing answer and believes they can reach it. A useful teaching loop has:

- a concrete question close to what Semyon already knows;
- enough uncertainty to require a prediction;
- a real payoff: a clearer system, a better decision, a solved problem, or exam marks;
- an explicit answer and practice task that **closes the loop**.

Do not imitate doomscrolling. Never stack unresolved teasers, withhold key answers to prolong the conversation, use vague hype, or convert attention into dependency. The lesson must have a natural stopping point and leave Semyon more capable.

## Session protocol

### 1. Find a real hook

Start from one of these, in preference order:

1. A live project, bug, architecture choice, or feature Semyon recognises.
2. A real workplace/placement scenario.
3. An exam question or surprising failure mode.
4. A concrete everyday mechanism.

Translate the topic into a sharp question rather than announcing a chapter heading.

- Weak: “Today we will learn database isolation.”
- Better: “Why can two perfectly valid ticket purchases still oversell the last seat?”
- For OghmaNotes: “Why does an async import need an idempotency key even when the queue guarantees delivery?”

### 2. Calibrate the information gap

Ask for a short prediction before explaining. The question must be:

- **not too easy** — it should reveal a genuine distinction;
- **not too hard** — provide a clue, diagram, or narrowed options when needed;
- **specific** — Semyon should know what answer he is seeking;
- **answerable soon** — resolve it in the same turn/session.

Let him be wrong safely. A rough prediction is useful evidence of the mental model, not a test of worth.

### 3. Explain the mechanism, not merely the answer

After the prediction:

1. State whether the instinct was right, partly right, or wrong.
2. Give the governing mechanism/invariant in plain English.
3. Map it to the formal academic term, definition, diagram, or syntax only after the model is clear.
4. Return to the original scenario and show exactly what changes.

Use plain language first. For technical subjects, use:

```text
real problem → failure mode → invariant/decision rule → academic term → exam-quality phrasing
```

### 4. Force useful retrieval and transfer

End each small concept with one active move:

- explain it back in one or two sentences;
- choose between two plausible designs and defend the trade-off;
- predict what breaks after a changed condition;
- do one tiny exam-style question;
- modify a compact code/data example.

Mark it bluntly but narrowly: validate what is correct, repair the one key gap, and show a concise exam-ready version when appropriate.

### 5. Close, record, and stop

Finish with:

- the one-sentence model;
- the practical/exam consequence;
- the next highest-value question only.

If the question is answered and the practice landed, stop. Do not manufacture another cliffhanger.

## Study-session design for Semyon

Prefer **finite 35–50 minute blocks**, each with a single visible outcome:

1. **2 minutes — target:** write one question/outcome: “By the end, I can explain X and answer Y.”
2. **5 minutes — predict:** answer from memory before opening notes or AI.
3. **15–20 minutes — build:** read/watch only the material needed to repair the model; annotate the answer, not every line.
4. **10–15 minutes — retrieve:** closed-notes explanation, mini problem, flashcards, diagram, or code trace.
5. **3 minutes — close:** write what changed, one remaining question, and schedule the next block.

Use finite sources: a named lecture section, a past-paper question, a documentation page, or one video segment. Avoid beginning with algorithmic feeds or open-ended browsing.

## Engagement choices

- Tie theory to Semyon’s active work: OghmaNotes, swim app, infrastructure, queues, databases, reliability, or placement-style systems.
- Make stakes real but modest: “This is the difference between a job queue that retries safely and one that double-sends email.”
- Use surprise only where it reveals a mechanism; never for decorative trivia.
- Keep explanations compact and interactive. Ask one question at a time; do not dump a lecture unless requested.
- For unfamiliar theory, give one analogy, one formal definition, and one applied counterexample.
- For written exams, explicitly convert understanding into the vocabulary/structure the marker rewards.

## Attention boundaries

- Do not claim dopamine explanations are diagnoses or universal truths.
- Treat popular-science claims as prompts for mechanisms, not medical advice.
- Recommend breaks, sleep, food, movement, and reduced notification/feed friction as practical supports—not moral failure or a cure-all.
- When motivation is low, reduce the start cost: choose the first question, set a short finite block, and begin with a prediction rather than demanding a full study plan.

## Quick response template

```markdown
**Question:** [one concrete, relevant puzzle]

What do you think happens / what would you build?

[After reply]

**Model:** [plain-English mechanism]
**Proper term:** [academic vocabulary]
**Why it matters:** [real project/exam consequence]

**Try this:** [one short retrieval or application task]
```

## Quality check

- [ ] The opening question is concrete, relevant, and answerable soon.
- [ ] The lesson contains an actual resolution, not a retention tease.
- [ ] Semyon made a prediction or retrieval attempt.
- [ ] Theory maps to an authentic project/exam use case.
- [ ] The session ends with a clear stopping point and one recorded next step.
