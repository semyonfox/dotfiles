# Antigravity/Gemini vision handoff

Use this when Semyon wants Gemini's strong/cheap vision used as an image-description worker for Claude/Codex/Fable, not as the lead reasoning model and not through Hermes provider config.

## Readiness checks

```bash
command -v agy
agy models
```

Pick a Gemini Flash lane when available; Semyon's current preference is to use Gemini for pixels, then let the stronger coding/reasoning model make decisions.

## Wrapper pattern

Preferred durable wrapper in dotfiles:

```bash
agy-vision-describe <image-path> [focus]
```

Wrapper behavior:

- resolves the image path
- scopes Antigravity with `--add-dir "$(dirname "$IMAGE")"`
- uses `--mode plan` so it describes rather than edits
- calls a Gemini Flash model
- asks for a dense structured visual handoff: layout, text, colours, spacing, hierarchy, components, icons, states, affordances, and anomalies

Fallback direct command:

```bash
IMAGE=/path/to/image.png
agy --model "Gemini 3.5 Flash (Low)" \
  --mode plan \
  --add-dir "$(dirname "$IMAGE")" \
  -p "Use Gemini vision on this image. Return visible observations only for another model: layout, exact text, colours, spacing, hierarchy, component states, icons, anomalies, clipping, unreadable text, contrast issues, and confidence. Separate observations from guesses. Do not recommend redesigns or make final taste/product decisions: $IMAGE" \
  --print-timeout 5m
```

## Routing rule

Do not frame this as "wire Gemini into Hermes" unless the user explicitly asks for Hermes provider configuration. For this workflow, Gemini lives behind Antigravity CLI (`agy`) and is invoked by agent instructions (`AGENTS.md`, `CLAUDE.md`, Codex defaults, or skills) as a helper.

The lead model should treat Gemini's output as visual evidence, not final product judgment. Use Claude/Codex/Fable/Opus for implementation, taste, architecture, and verification.

## Anti-taint protocol

Gemini is the eyes on the ground, not the editor/director. Ask for **visible observations only**, then have the lead model decide what matters and how to patch.

Good Gemini outputs contain:

- exact visible text
- spatial layout and grouping
- colours and contrast
- typography and approximate sizes
- component states and affordances
- icons and imagery
- alignment/spacing/hierarchy
- visual glitches or anomalies
- clipping, overlaps, low contrast, unreadable text, cursor artifacts, broken scale
- confidence or region/coordinate hints when useful

Avoid letting Gemini drive:

- final UI taste
- product/story direction
- architecture choices
- redesign strategy
- implementation decisions

If Gemini includes speculative recommendations anyway, strip or down-rank them before feeding its report to Claude/Codex/Fable/Opus. Preserve concrete pixel observations; ignore consultant slurry.

Preferred direct prompt:

```text
Use Gemini vision on this image. Return visible observations only for another model: layout, exact text, colours, spacing, hierarchy, component states, icons, anomalies, clipping, unreadable text, contrast issues, and confidence. Separate observations from guesses. Do not recommend redesigns or make final taste/product decisions: <image>
```

## Good prompts

For UI/screenshot work, ask Gemini for:

- exact visible text
- spatial layout and grouping
- colours and contrast
- typography and approximate sizes
- component states and affordances
- icons and imagery
- alignment/spacing/hierarchy
- visual glitches or anomalies
- enough detail for another model to implement or review without seeing the image
