# Model selection notes

This skill is for answering questions like:
- Which Codex/OpenAI model should I use here?
- Is the bigger model worth it?
- What does my actual usage/cost look like?

## Reliable local signals
- `npx ccusage@latest --json` gives overall usage totals.
- `npx ccusage@latest codex --json` gives Codex-specific usage grouped by day.
- `~/.codex/models_cache.json` shows which models Codex currently exposes in this profile.
- `npx @openai/codex doctor` can show the active model config and whether the current profile is healthy.

## Interpreting the result
- If the task is reasoning-heavy, codebase-heavy, or tool-heavy, prefer the strongest available model.
- Mini models are for cheap/simple work, not for tasks where the cost of a wrong answer is higher than the token savings.
- If the user says a larger model is “dirty cheap”, that is usually enough to justify using it for anything non-trivial.

## What to report back
- Name the model(s) actually available in the local Codex catalog.
- Report the usage total from ccusage if the user asked about cost.
- If the exact live pricing page is not accessible, be explicit that the answer is based on observed local spend, not a live price scrape.
- Give a recommendation in plain terms: "use X here" plus one sentence of why.
