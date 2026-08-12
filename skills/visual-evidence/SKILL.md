---
name: visual-evidence
description: "Use when inspect slide decks, SVG or vector-heavy compositions, complex infographics, and production visual-reference comparisons with Gemini through the local agy CLI. Use when exact rendered evidence materially affects those tasks. Do not use for generic visuals, ordinary frontend work, or simple image viewing, and do not let Gemini make architecture, taste, or product decisions."

metadata:
  harness: [claude, codex]
---

# Visual evidence

Use Gemini through `agy` as a specialist observer for slide decks, SVG/vector compositions, complex infographics, and production visual QA against a reference. Ask for exact visible text, layout, hierarchy, colors, spacing, component states, icons, clipping, contrast, anomalies, and confidence. Separate observations from guesses.

Do not invoke it for generic visual tasks, ordinary screenshots, routine frontend implementation, or simple image inspection when the lead model, source code, DOM, or browser snapshot is sufficient.

```bash
IMAGE=/absolute/path/to/image.png
AGY_MODEL="Gemini 3.5 Flash (Low)"
agy --model "$AGY_MODEL" --mode plan --add-dir "$(dirname "$IMAGE")" --print-timeout 5m -p "Use Gemini vision on this image. Return visible observations only for another model: exact text, layout, colours, spacing, hierarchy, component states, icons, clipping, unreadable text, contrast issues, anomalies, and confidence. Separate observations from guesses. Do not recommend redesigns, architecture, or product decisions: $IMAGE"
```

Keep concrete observations as evidence and down-rank speculation. The lead model makes the design, architecture, product, and implementation judgments.
