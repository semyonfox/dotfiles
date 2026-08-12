# Frontier AI model comparison and routing research

Use when comparing current hosted AI model families, reasoning levels, price tiers, or practical routing choices for a user who wants an actionable balance point rather than generic launch-post summaries.

## Source priority

1. Official model catalog/API docs for model IDs, aliases, context windows, max output, pricing, modality/tool support, knowledge cutoffs, and supported reasoning values.
2. Official reasoning/model guidance for semantics of `reasoning.effort`, defaults, pro/standard modes, and billing caveats.
3. Official launch/system-card posts for benchmark claims and positioning.
4. Third-party articles only for interpretation, quoted staff comments, or independent benchmark context. Label them as secondary.

## Answer shape

- Start with the likely routing/default recommendation in one sentence.
- Separate **documented facts** from **heuristic routing judgement**.
- Include a compact model table: model ID/name, role, input/output price, context, max output, cutoff, supported reasoning levels.
- Include a reasoning-level mapping table by workload, e.g. fast classification, normal coding, agentic coding, deep research/security review, long-horizon parallel agent work.
- Compute representative request costs with a tool, e.g. `input_price * input_mtokens + output_price * output_mtokens`; state that hidden reasoning tokens/tool calls can dominate real cost.
- For “matching performance balance,” give a ladder: cheapest viable model, balanced default, quality fallback, flagship, last-resort max/pro/multi-agent.
- If generating graphs, mark subjective routing plots clearly as heuristic, not benchmark data.

## Useful artifact pattern

Create a small deliverable directory containing:

- `comparison.md` with sources and caveats.
- `matrix.svg/png` for specs/routing matrix.
- `cost.svg/png` for representative text-token cost.
- `balance.svg/png` for heuristic capability vs cost/latency map.

If SVG-to-PNG conversion is needed, try a Python library first, then a system renderer such as ImageMagick/`convert` or `rsvg-convert` if available. Do not persist a broad rule that a converter is missing just because one environment lacked it.

## Pitfalls

- Do not imply reasoning levels map one-to-one across model generations unless the docs say so. Newer families may add/remove levels or add separate modes such as `pro` or multi-agent/ultra workflows.
- Do not treat launch benchmark claims as universal. Use them as vendor claims unless independently verified.
- Do not hide cost assumptions. Always state the sample token mix and that reasoning tokens are billed as output tokens where applicable.
- Do not overfocus on the flagship. The useful answer is usually the routing boundary where the cheaper tier stops being enough.
