# Relay Optimiser Writing Audit: Example

Use as an example of why technical posts need a rule-layer audit before prose.

## Source hierarchy used

1. Rule/validation helper: relay size, mixed-composition validation, selected type/category.
2. Freestyle generator: category filtering, freestyle-time eligibility, disjoint A/B/C selection.
3. Medley generator: fixed stroke positions, one swimmer per leg, mixed-composition state.
4. Focused optimiser tests: exact assignment, mixed composition, disjoint teams, large-roster behaviour.
5. Git history: distinguish the prior exhaustive/heuristic implementation from the current one.

## Correct explanatory split

| Layer | Accurate statement |
| --- | --- |
| Freestyle rule | Select the quickest eligible four for a single category; for mixed selection, select the required two-and-two category composition. |
| Medley rule | Fill Back, Breast, Fly, and Free once each, with a swimmer appearing on at most one leg; mixed adds the required two-and-two composition with free category placement across legs. |
| Historical code | It unnecessarily enumerated freestyle groups and used a large-roster shortcut. This was an implementation limitation, not a property of the freestyle rule. |
| Current technique | Compact state selection is an implementation strategy; bitmask assignment is material for medley because stroke slots must be filled. |
| Multi-team semantics | Choose fastest valid A, remove its entrants, then choose B from the remainder. This is sequential priority, not global multi-team balancing. |

## Editorial pitfall

Do not turn internal category constants into looser prose without checking the UI/rule layer. If the product exposes `Open`, `Female`, and `Mixed`, retain those labels unless the product itself provides an explicit reader-facing translation.
