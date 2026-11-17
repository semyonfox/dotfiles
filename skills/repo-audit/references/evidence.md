# Review evidence

Why `repo-audit` assigns the roles it does. Add one row per model after each run. When a new model ships, put it in one slot of a real audit before changing the roles.

## Runs

| Date | Repo | Model | Step | Findings | Unique | Proved | Dropped | Notes |
| --- | --- | --- | --- | ---: | ---: | ---: | ---: | --- |
| 2026-11-11 | SWIM | `gpt-6.1-sol` | blind | 6 | 4 | 3 | 0 | 9 min. Only one to run code |
| 2026-11-11 | SWIM | `claude-fable-5-2` | blind | 19 | 9 | | 0 | Missed the result and split invariant |
| 2026-11-11 | SWIM | `claude-opus-5-5` | blind | 17 | 5 | | 0 | Missed the commerce 500-row cap. Inflated severity |
| 2026-11-12 | SWIM | all three | cross-review | | | | | Fable found the deploy-breaking Docker image. Sol found the most money bugs |
| 2026-11-12 | OghmaNotes | `gpt-6.1-sol` | blind | 4 | 3 | 2 | 0 | Narrow, nothing on cost or security |
| 2026-11-12 | OghmaNotes | `claude-fable-5-2` | blind | 8 | 5 | 4 | 0 | Quantified the quiz spend and dated the save-fence bug |
| 2026-11-12 | OghmaNotes | `gpt-6.1-sol` | implement | | | | | Re-embedded vault imports, left a CI-breaking assertion |
| 2026-11-12 | OghmaNotes | `claude-fable-5-2` | cross-review | 8 | | 4 | 0 | Best failure-path pass |
| 2026-11-12 | Branchroom | `gpt-6.1-sol` | blind | 7 | 2 | 4 | 0 | Missed both transport show-stoppers |
| 2026-11-12 | Branchroom | `claude-fable-5-2` | blind | 21 | 8 | 9 | 0 | Only one to find the gzip and fsck show-stoppers |
| 2026-11-12 | Branchroom | `claude-opus-5-5` | security | 9 | 5 | 1 | 2 | Only reviewer to look outside the obvious routes. Two findings dropped as design choices |
| 2026-11-12 | Branchroom | `gpt-6.1-sol` | implement | | | | | Two high regressions with every check green |
| 2026-11-12 | Branchroom | `claude-fable-5-2` | cross-review | 9 | | 7 | 0 | Proved both regressions with the built binary |

The free OpenCode models (DeepSeek V4.1 Flash, GLM-5.3-Flash) produced output once in six attempts across these runs, so they have no slot.

## Public benchmarks, November 2026

Single-diff review, so they reward precision more than the open audits above.

| Benchmark | `gpt-6.1-sol` | `claude-opus-5-5` | `claude-fable-5-2` |
| --- | --- | --- | --- |
| MacroscopeBench, high effort: recall, precision, cost | 66.2%, 91.3%, $0.56 | 68.1%, 78.9%, $1.30 | 66.9%, 87.9%, $3.01 |
| CodePanel: caught, false alarms per clean PR, cost | 89%, 0.9, $0.04 | 90%, 1.7, $0.15 | not run |

List prices per MTok, input and output: Sol $2 and $10 on Codex credits, Opus $4 and $20, Fable $8 and $40.
