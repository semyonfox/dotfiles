# Model routing benchmark snapshot

Snapshot: **2026-07-31**. Use it as directional routing evidence, not a permanent leaderboard.

## method

- Intelligence is Artificial Analysis Intelligence Index v4.1. It combines agentic work, coding, science, reasoning, knowledge, and long-context evaluations. Scores are not percentages.
- The comparable headline uses max or adaptive-max effort. Lower efforts can be materially faster and cheaper per task: for example, Sol medium scored 54 at 74 t/s, while Sol max scored 59 at 66 t/s.
- Speed is streamed output after generation begins. It does not include hidden reasoning or time to first answer token, so it is not end-to-end latency.
- Use benchmarks only as evidence for the 1–10 intelligence score in the routing skill. Taste is Semyon's judgement of interaction, personality, collaboration, and product/code judgement; it is not benchmark-derived.
- Treat cost as a 1–10 personal effective-availability score under Semyon's subscriptions and limits. The [AI Usage Ledger](https://seol.semyon.ie/p/dpGn_V9KiUUv7IE0CXE7RA/) informs it; API prices below are factual context, not routing scores.
- Fast Mode is excluded. Use standard model speed; treat Spark as a separate model.
- Kimi K3 remains in this benchmark snapshot for historical comparison but is excluded from active routing because its effective personal billing is not viable.
- Claude usage is scarce in the personal routing policy. Sonnet and Opus should be used for focused UI/taste work, implementation ideas, or review; Fable is request-only for the next few months and must never be auto-selected.

## comparable snapshot

| model | AA intelligence | output t/s | current input/output MTok | important caveat |
| --- | ---: | ---: | ---: | --- |
| Claude Opus 5 max | 61 | 54.8 | $5 / $25 | Highest score here; slow and expensive. |
| Claude Fable 5 max | 60 | 73.5 | $10 / $50 | Benchmark includes Opus 4.8 fallback for classified domains. |
| GPT-5.6 Sol max | 59 | 65.9 | $5 / $30 | Strong OpenAI ceiling; max has high reasoning latency. |
| Kimi K3 | 57 | 32.2 | $3 / $15 | Historical comparison only; excluded from active routing because of effective personal billing. |
| GPT-5.6 Terra max | 55 | 135.7 | $2 / $12 | Default medium is lower ceiling but a better interactive tradeoff. |
| Claude Sonnet 5 max | 53 | 74.3 | $2 / $10 through 2026-08-31, then $3 / $15 | Max is unusually verbose; medium is the practical lane. |
| GPT-5.6 Luna max | 51 | 188.3 | $0.20 / $1.20 | Max score overstates the lane needed for simple bulk work. |
| GPT-5.3-Codex-Spark | n/a | >1,000 vendor figure | Codex Pro research-preview quota | No comparable AA v4.1 score found; text-only 128K and does not run tests by default. |

## sources

- [OpenAI model catalog and current Sol/Terra/Luna prices](https://developers.openai.com/api/docs/models)
- [OpenAI Codex Spark announcement](https://openai.com/index/introducing-gpt-5-3-codex-spark/)
- [Anthropic Opus 5 availability and pricing](https://www.anthropic.com/claude/opus)
- [Anthropic Sonnet 5 availability and promotional pricing](https://www.anthropic.com/news/claude-sonnet-5)
- [Anthropic Fable 5 pricing and fallback behavior](https://www.anthropic.com/news/claude-fable-5-mythos-5)
- [OpenCode Kimi K3 usage, context, and price](https://opencode.ai/en/data/moonshot/kimi-k3)
- Artificial Analysis: [Opus 5](https://artificialanalysis.ai/models/claude-opus-5), [Fable 5](https://artificialanalysis.ai/models/claude-fable-5), [Sonnet 5](https://artificialanalysis.ai/models/claude-sonnet-5), [Sol](https://artificialanalysis.ai/models/gpt-5-6-sol), [Terra](https://artificialanalysis.ai/models/gpt-5-6-terra), [Luna](https://artificialanalysis.ai/models/gpt-5-6-luna), and [Kimi K3](https://artificialanalysis.ai/models/kimi-k3)
