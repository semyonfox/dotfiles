# Archived source skill: `llm-model-selection`

Preserved after consolidation into `hermes-agent`. Use the umbrella first; consult this for detailed recipes.

---

---
name: llm-model-selection
description: Choose between available LLM/Codex models using local availability data, usage reports, and task complexity.
---

# LLM model selection

Use this skill when the user asks which model to use, wants pricing/usage comparisons, or asks whether to spend more for a bigger model.

## Core approach
1. Inspect the local model catalog or CLI docs first. Do not assume that every model string mentioned in binaries is actually selectable in the current UI/CLI profile.
2. Compare two separate things:
   - availability: what the local client/catalog exposes
   - economics: what the usage report says the user is actually spending
3. Pick the smallest model that comfortably covers the task, but do not undercut on reasoning for subtle, multi-step, or tool-heavy work.
4. When the task is ambiguous, bias toward the stronger model if the cost difference is small relative to the value of correctness.

## Practical heuristics
- Use the frontier/default model for anything requiring real reasoning, codebase navigation, tool use, or careful tradeoffs.
- Use a cheaper mini model only for linear, low-risk, repetitive, or classification-style work.
- If the user explicitly says the larger model is cheap enough, treat that as a strong signal to favor quality over marginal savings.
- Distinguish Codex-supported models from general OpenAI API models. Some names may appear in binaries, docs, or migration text without being selected by the current environment.

## Evidence sources to check
- `ccusage` for spending and usage shape.
- The local Codex model cache/config for what is actually available in this profile.
- CLI help/docs for naming and model-specific guidance.

## Output style
- Be concrete: name the model, state why, and call out the tradeoff in one or two lines.
- If you give a recommendation, pair it with the rough cost/usage evidence that supports it.
- Avoid pretending pricing is exact if you only have local usage totals. Say whether you are using live pricing or observed spend.

## Support files
- `references/llm-model-selection-references-model-selection-notes.md` for a compact workflow and interpretation notes.
