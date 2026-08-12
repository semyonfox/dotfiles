# Antigravity/Gemini visual handoff

Use this when a coding/reasoning agent needs high-fidelity visual context from an image, screenshot, UI mock, diagram, or browser capture.

## Pattern

Do not build a local wrapper or route this through Hermes provider config. Call Antigravity CLI (`agy`) headlessly, similar to `claude -p`, and feed the returned visual description back into the lead model.

```bash
IMAGE=/path/to/image.png
agy --model "Gemini 3.5 Flash (Low)" \
  --mode plan \
  --add-dir "$(dirname "$IMAGE")" \
  --print-timeout 5m \
  -p "Use Gemini vision on this image. Return visible observations only for another model: layout, exact text, colours, spacing, hierarchy, component states, icons, anomalies, clipping, unreadable text, contrast issues, and confidence. Separate observations from guesses. Do not recommend redesigns or make final taste/product decisions: $IMAGE"
```

## Role split

- Gemini/Antigravity: efficient visual perception and detailed UI/layout observations.
- Claude/Codex/Fable/Opus/lead agent: reasoning, product judgment, implementation, verification, and final decisions.

## Anti-taint protocol

Gemini output is visual evidence, not authority. Preserve concrete pixel observations — exact text, layout, spacing, clipping, contrast, broken scale, low readability, and confidence. Strip or down-rank speculative recommendations before feeding the report to the lead model. Do not let Gemini drive final UI taste, product/story direction, architecture choices, redesign strategy, or implementation decisions.

## Pitfalls

- Avoid creating helper wrappers unless the user explicitly asks; the durable instruction should be the direct headless `agy` command.
- Avoid treating Gemini as the lead reasoning/coding model just because it handled the image.
- Include `--add-dir "$(dirname "$IMAGE")"` so the CLI can access local images outside the current workspace.
- Use `--mode plan` for read-only visual description unless actual edits are intentionally delegated to Antigravity.
