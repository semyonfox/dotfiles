# Hermes/Codex Token Accounting and Limits

Use this reference when Semyon asks for token max, agent-loop records, or price/API behavior for Hermes running through Codex/ChatGPT OAuth.

## What To Check

1. Inspect live Hermes config with `hermes config` or `hermes config path` + config readout.
2. Resolve context length from Hermes source/runtime, not from generic model marketing pages. For the current Codex OAuth route, `openai-codex:gpt-5.5` and `openai-codex:gpt-5.4` resolve to a 272,000-token context window in Hermes, while `gpt-5.3-codex-spark` resolves to 128,000. Anthropic `claude-opus-4-8` resolves to 1,000,000.
3. Apply compression settings separately from model context. With `compression.threshold: 0.7`, a 272,000-token route starts compression around 190,400 prompt/context tokens. With `target_ratio: 0.2`, the target compressed body is around 38,080 tokens, plus protected head/tail messages.
4. Distinguish context max from output cap. Hermes reads `HERMES_MAX_TOKENS`, then `model.max_tokens`, then provider runtime `max_output_tokens` where available. For the ChatGPT Codex backend, Hermes intentionally does not pass `max_output_tokens`; backend defaults/limits apply. For normal OpenAI-compatible/API routes, Hermes passes the cap as `max_tokens`, `max_completion_tokens`, or `max_output_tokens` depending on API shape.
5. Query `~/.hermes/state.db` for durable loop records when the user asks whether there are records. `sessions` stores model/source/message/tool/API-call counts, token buckets, billing route, cost status/source/version, and estimated/actual cost fields. `messages` stores per-message content, tool calls, token count, finish reason, and reasoning/Codex item fields.

## Billing Interpretation

Hermes treats provider `openai-codex` as `billing_mode='subscription_included'`. Cost status should be reported as included/subscription-covered rather than direct API billing.

`ccusage` dollar figures for Codex are still useful as API-equivalent burn estimates, but they are not necessarily money charged to Semyon when the route is ChatGPT/Codex OAuth. Say this explicitly to avoid confusing API-equivalent spend with actual subscription billing.

For normal API providers, Hermes estimates cost through `agent/usage_pricing.py`: OpenRouter/Nous/endpoints via model metadata where available, Anthropic/OpenAI/etc. from built-in official pricing snapshots, and unknown/custom/local routes as unknown unless endpoint metadata exists.

## Reporting Shape

Report these as separate lines or sections:

- Token/context max and compression threshold.
- Output cap behavior, especially whether a cap is configured and whether the backend honors it.
- Durable agent-loop record locations and what fields are stored.
- Recent aggregate usage from `hermes insights --days N` or state DB queries.
- Billing route: subscription-included vs API-metered.
- ccusage: usage/API-equivalent cost, not necessarily actual bill.

Avoid saying "remaining limit" unless a CLI or provider endpoint exposed remaining quota directly.