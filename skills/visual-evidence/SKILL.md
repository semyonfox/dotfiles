---
name: visual-evidence
description: "Use when slide decks, vector compositions, complex infographics, or visual-reference QA need rendered evidence from Gemini via agy — not ordinary frontend or simple image viewing."

metadata:
  harness: [claude, codex]
---

# Visual evidence

Use Gemini through `agy` as a specialist observer for slide decks, SVG/vector compositions, complex infographics, and production visual QA against a reference. Ask for exact visible text, layout, hierarchy, colors, spacing, component states, icons, clipping, contrast, anomalies, and confidence. Separate observations from guesses.

Do not invoke it for generic visual tasks, ordinary screenshots, routine frontend implementation, or simple image inspection when the lead model, source code, DOM, or browser snapshot is sufficient.

If there is an error, either usage limits reached or auth failures or lack of availability, do not continue using agy, and do not use this skill.

```bash
IMAGE=/absolute/path/to/image.png
AGY_MODEL="Gemini 3.5 Flash (Low)"
agy --model "$AGY_MODEL" --mode plan --add-dir "$(dirname "$IMAGE")" --print-timeout 5m -p "Return visible observations only: exact text, layout, colours, spacing, hierarchy, component states, icons, clipping, unreadable text, contrast issues, anomalies, and confidence. Separate observations from guesses. Do not recommend redesigns, architecture, or product decisions, observation only: $IMAGE"
```

Keep concrete observations as evidence and down-rank speculation. The lead model makes the design, architecture, product, and implementation judgments, this model is only a pair of eyes.
