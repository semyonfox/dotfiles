# Model routing benchmark snapshot

Snapshot: **2026-10-04**. Directional evidence, not a leaderboard to maintain. Refresh only when a routing decision depends on it.

## method

- Scores are Artificial Analysis Intelligence Index v4.3.2 at max effort, from each model's own AA page. Real medium/high runs score a few points lower: GPT-6.1 Sol is 48 at medium and 52 at max.
- Never compare across index versions. Aggregator sites mix v4.1 and v4.3.2 scores and misrank models.
- Cost per task is AA's average across the index run. It captures verbosity, which per-token prices hide.
- Codex credits equal API list price, for example 50/250 credits per MTok for GPT-6.1 Sol = $2/$10.

## snapshot

| model | AA v4.3.2 | cost/task | input/output per MTok | output t/s | caveat |
| --- | ---: | ---: | ---: | ---: | --- |
| Claude Opus 5.5 | 58 (#1) | $5.98 | $4 / $20 | 92 | |
| Claude Sonnet 5.5 | 56 (#2) | $7.67 | $2 / $10 | 131 | very verbose: 420M output tokens on the index |
| Claude Fable 5.1 | 53 (#5) | $7.63 | $10 / $50 | 66 | verbose; 50% weekly cap on Max |
| GPT-6 Astra | 53 (#7) | $3.26 | $10 / $50 | 60 | cache reads $1/MTok, ruinous on credits |
| GPT-6.1 Sol | 52 (#11) | $0.72 | $2 / $10 | 52 | best value on credits |
| GPT-5.6 Sol | 47 (#26) | $1.99 | $4 / $20 | 79 | superseded by 6.1 Sol |
| GPT-6 Luna | 38 | $0.07 | $0.10 / $0.50 | 141 | slow time to first token |

## sources

- Artificial Analysis: [Opus 5.5](https://artificialanalysis.ai/models/claude-opus-5-5), [Sonnet 5.5](https://artificialanalysis.ai/models/claude-sonnet-5-5), [Fable 5.1](https://artificialanalysis.ai/models/claude-fable-5-1), [GPT-6 Astra](https://artificialanalysis.ai/models/gpt-6-astra), [GPT-6.1 Sol](https://artificialanalysis.ai/models/gpt-6-1-sol), [GPT-5.6 Sol](https://artificialanalysis.ai/models/gpt-5-6-sol), [GPT-6 Luna](https://artificialanalysis.ai/models/gpt-6-luna)
- [OpenAI credit rate card](https://help.openai.com/en/articles/11481834-chatgpt-rate-card-business-enterpriseedu-credit-based-pricing)
- [Claude Max limits and Fable cap](https://claudemax.shop/en/blog/claude-max-5x-vs-20x)
