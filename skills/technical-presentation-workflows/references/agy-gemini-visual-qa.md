# Antigravity/Gemini visual QA for decks and UI

Session lesson: for visual fidelity work, route `agy`/Gemini as a headless visual-description worker rather than making it the lead reasoning/coding model.

## Direct headless command pattern

```bash
IMAGE=/path/to/screenshot.png
AGY_MODEL="Gemini 3.5 Flash (Low)"
agy --model "$AGY_MODEL" \
  --mode plan \
  --add-dir "$(dirname "$IMAGE")" \
  --print-timeout 5m \
  -p "Use Gemini vision on this image. Return visible observations only for another model: layout, exact text, colours, spacing, hierarchy, component states, icons, anomalies, clipping, unreadable text, contrast issues, and confidence. Separate observations from guesses. Do not recommend redesigns or make final taste/product decisions: $IMAGE"
```

Model/thinking selection:

- `Gemini 3.5 Flash (Low)` — default for normal screenshots and quick UI checks.
- `Gemini 3.5 Flash (Medium/High)` — dense UI, small text, diagrams, slide decks, multi-image comparisons, or when layout issues are subtle.
- Pro variants — only when visual extraction itself needs deeper reasoning; do not use Pro by default.

## Role split

- Claude/Fable/Opus/Codex: lead author, taste, structure, implementation, final judgement.
- Gemini/agy: visual extraction, layout inventory, screenshot criticism, obvious rendered failures.

In the semyon.ie test, Claude gave better copy/taste but missed a rendered slide clipping/layout problem. Gemini produced a more visually complete first-pass deck but with more generic/dashboard-like phrasing. Best workflow: lead model creates/patches, render screenshots, `agy` critiques visually, lead model applies judgement and fixes, repeat.

## Anti-taint protocol

Gemini output should enter the lead model's context as **visual evidence**, not authority. Ask Gemini for visible observations only:

- exact visible text
- spatial layout and grouping
- colours, contrast, typography, approximate sizes
- component states, icons, imagery, and affordances
- alignment, spacing, hierarchy
- clipping, overlaps, unreadable text, cursor artifacts, broken scale, low contrast
- region/coordinate hints and confidence when possible

Do not ask Gemini for final taste, architecture, product direction, story decisions, or redesign strategy. If it includes speculative recommendations anyway, strip or down-rank them before feeding the handoff to Claude/Fable/Opus/Codex. Preserve concrete pixel facts; let the lead model decide what matters and how to patch.

Preferred observation-only prompt shape:

```text
Use Gemini vision on this image. Return visible observations only for another model: layout, exact text, colours, spacing, hierarchy, component states, icons, anomalies, clipping, unreadable text, contrast issues, and confidence. Separate observations from guesses. Do not recommend redesigns or make final taste/product decisions: <image>
```

## Pitfalls

- Do not create wrapper scripts for this flow unless Semyon explicitly asks. He prefers agents to call `agy` directly, like `claude -p`.
- Do not wire this through Hermes provider config when the task is about local agent orchestration; the durable integration point is the markdown/skill guidance and direct CLI call.
- Do not treat Gemini's recommendations as final taste. It is the eyes, not the brain.
