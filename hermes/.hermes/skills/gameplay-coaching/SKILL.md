---
name: gameplay-coaching
description: "Use when coaching a player through game puzzles."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]

metadata:
  harness: [hermes]
---

# Gameplay Coaching

## When to Use

Use when helping someone play, debug, optimise, or understand a game—especially programming, automation, logic, factory, simulation, and Zachtronics-style puzzle games. This is coaching for an existing game, not game design or implementation.

## First establish the help contract

Match the requested spoiler level exactly:

- **Hints / no way:** give an observation and a question or bounded experiment; do not provide an instruction sequence, exact route, final code, or a fully worked strategy.
- **Nudge:** identify one subsystem, resource, or invariant to inspect, without resolving it.
- **Explain a mechanic:** define it accurately and relate it to the visible state.
- **Solution / optimise it:** only give a concrete route, code, or step list when explicitly requested.

Treat screenshots as partial evidence. Read the goal, code/state, relevant metric panel, and execution trace if visible before diagnosing. If the goal or metric definition is not visible, say what is known versus uncertain rather than filling the gap with genre intuition.

## Puzzle-optimisation workflow

1. Identify the objective and which score is being chased: completion, cycles/time, activity/work, size/code, money, power, etc.
2. Inspect the player’s current solution as a timeline: what happens each turn/tick, which agent owns each resource, and where hand-offs block.
3. Separate **necessary ordering/synchronisation** from genuinely redundant work. An apparent duplicate move, wait, or hop may align parallel agents and improve elapsed time.
4. Verify unfamiliar score semantics from the in-game explanation, manual, reliable documentation, or demonstrated score changes. Never infer a metric solely from how many instructions of one type appear on screen.
5. Give the smallest non-spoiling next experiment: remove or move one operation, trace two values/ticks, or compare a score after a controlled change.
6. After a correction, acknowledge it plainly, retract the incorrect premise, and update the hint from the actual dependency. Do not defend the earlier read.

## Programming-puzzle hints

Useful non-spoiler hint forms:

- “Trace two values/ticks and mark when each register/file/queue changes.”
- “Which agent is blocked here, and which instruction releases it?”
- “Does this instruction do useful work, or is it deliberately pacing a hand-off?”
- “Which metric changes if you preserve the same schedule but reduce one transfer?”
- “Where is the resource created, and does it need to exist before travel?”

Prefer a single actionable observation, then let the player make the leap. Avoid turning a requested hint into an optimisation walkthrough.

## Screenshot interpretation pitfalls

- Do not label repeated-looking commands as redundant without tracing their timing and dependencies.
- Do not conflate elapsed time with total work, code size, agent count, hops, or any game-specific score.
- Do not assume a register/file/queue behaves like a conventional variable; check the game’s blocking, overwrite, and ownership semantics.
- Do not over-explain after the player says they have solved a point; acknowledge the insight and move on.

## Tone

Be concise, collaborative, and game-literate. Celebrate a real optimisation without claiming credit for it. A little banter is welcome; unnecessary tutorial narration is not.

## Verification checklist

- [ ] The requested spoiler boundary is preserved.
- [ ] The response distinguishes observed facts from assumptions.
- [ ] Any metric claim is grounded in a game source or visible evidence.
- [ ] Timing and synchronisation were considered before calling an operation redundant.
- [ ] The hint gives one next thing to test, not a hidden complete solution.

## References

- `references/exapunks-optimisation-notes.md` — compact guidance for metric and timing analysis in EXAPUNKS-style programming puzzles.
