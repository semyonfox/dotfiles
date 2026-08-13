---
name: model-routing
description: "Use before delegating implementation, orchestrating agents, escalating reasoning effort, requesting cross-model review, or deciding between Sol, Terra, Luna, Spark, Opus, Sonnet, or Fable. Select the decision owner, implementer, effort, and review path; do not invoke merely because several models are available."

metadata:
  harness: [claude, codex]
---

# Model routing

Choose from task shape and three personal axes: intelligence, taste, and effective cost—not prestige.

## current matrix

Use the 1–10 personal matrix below. **Intelligence** is unsupervised problem-solving ability. **Taste** is judgement, interaction, personality, and what the model is like to work with, including UI/UX, copy, API/SDK design, code quality, and product detail. **Cost** is effective value and availability under Semyon's subscriptions and limits, including model pricing and thinking efficiency; higher is better and it is not literal API list price.

| model and access | intelligence | cost | taste | route when |
| --- | ---: | ---: | ---: | --- |
| **GPT-5.6 Terra** (`gpt-5.6-terra`) | 8 | 10 | 6 | Default interactive implementation, bounded refactors, and focused review. |
| **GPT-5.6 Sol** (`gpt-5.6-sol`) | 9 | 9 | 6 | Difficult bounded investigation, architecture, debugging, and autonomous execution. |
| **GPT-5.6 Luna** (`gpt-5.6-luna`) | 6 | 10 | 5 | Clear high-volume transformation and tightly specified mechanical work. |
| **Claude Opus 5** (`claude-opus-5`) | 9 | 3 | 9 | Scarce UI/product lead, implementation-idea generator, difficult review, and second opinion. |
| **Claude Sonnet 5** (`claude-sonnet-5`) | 6 | 4 | 7 | Scarce lighter UI implementation, taste-aware review, copy, and product-facing assistance. |
| **Claude Fable 5** (`claude-fable-5`) | 10 | 1 | 10 | Request-only reserve for frontier judgement and final calls; never auto-select. |

Route lexicographically: reject models below either the task's intelligence or taste requirement; among those that pass, prefer the smallest sufficient model; use cost only to break equal-fit ties. Never accept weaker intelligence or taste to save cost.

Default ownership is deliberate: **Claude is the preferred UI/taste specialist, while the GPT-5.6 Codex family owns routine implementation and technical execution; Spark preserves the lead's context window by taking only low-intelligence repetitive units.** Use Claude sparingly because its allowance is scarce. Fable may own frontier judgement and final calls only when Semyon explicitly requests it. Cost is never a reason to accept weaker work when the task needs better judgement.

Keep **Codex Spark** (`gpt-5.3-codex-spark`) outside the scored matrix. Use it for one bounded repetitive file or independent unit—summaries, extraction, classification, boilerplate cleanup, or compact factual reports. Never give it broad repository edits or final judgement; the lead verifies and synthesises.

Exclude **Kimi K3** from active routing for now because its effective billing is not viable. Do not select it as lead, implementer, or reviewer unless Semyon explicitly re-enables it.

Keep **Fable 5 request-only** for the next few months because its allowance is extremely limited. Never auto-select, escalate to, or delegate to Fable. An explicit request for Fable in the current task is the only activation signal.

## orchestration matrix

Choose the decision owner separately from the implementer. A high-volume worker does not gain decision authority from speed.

| lane | orchestration role | decision rights | operating contract |
| --- | --- | --- | --- |
| **Fable 5** | request-only wise decision owner | Frontier judgement, architecture direction, taste, and final calls only after explicit request. | Never auto-select; when requested, frame the outcome, resolve escalations, and perform final synthesis. |
| **Opus 5** | scarce UI/product lead and senior reviewer | UI/product direction, strong recommendations, and consequential default calls when Fable was not requested. | Generate implementation ideas, plan ambiguous UI work, review Codex output, or implement when judgement and code cannot be separated. |
| **Sol** | persistent difficult-task implementer | Technical choices inside an agreed outcome and constraints. | Own hard investigation, debugging, refactors, and implementation through verification; stop only at completion or a concrete blocker. |
| **Terra** | default implementer | Local technical choices inside clear acceptance criteria. | Own routine features, fixes, tests, and focused review through proportionate verification. |
| **Luna** | high-volume implementation worker | No product, architecture, or ambiguous cross-file decisions. | Produce large amounts of clearly specified code or transformations; escalate ambiguity instead of inventing direction. |
| **Sonnet 5** | scarce taste-aware UI implementer and reviewer | Reversible UI choices and local judgement, not final authority. | Implement or review bounded UI work, copy, and UX when a focused Claude pass is worth its limited allowance. |
| **Spark** | context-saving micro-worker | None beyond the literal bounded unit. | Handle one repetitive independent unit and return compact structured output for lead verification. |

For orchestration: prefer **Claude for UI direction, implementation ideas, second opinions, and double-checking**, but spend focused passes rather than duplicating routine work. Use **Sonnet** for bounded UI implementation/review and **Opus** when ambiguity, consequence, or taste needs are higher. After an Opus-led direction pass, prefer a bounded Sonnet double-check; do not spend Opus twice unless the review is itself consequential. Let Claude implement directly when judgement and code are inseparable; otherwise let Claude frame or review and assign bulk execution to Codex. Never use Fable without an explicit current-task request. Assign **Sol** when persistence and difficult technical reasoning matter, **Terra** for normal execution, **Luna** for specified code volume, and **Spark** for microtasks. Workers must escalate ambiguity that crosses their decision boundary.

Read [references/benchmarks-2026-07-31.md](references/benchmarks-2026-07-31.md) when a numeric comparison, current price, or model availability affects the decision. Recheck official sources when the snapshot is over 30 days old or a model name no longer resolves.

## decisions

- Start with **Terra medium** for normal execution. Use **Sol medium/high** when the job needs more intelligence without high taste requirements.
- Prefer **Sonnet 5** for a bounded UI implementation or review and **Opus 5** for difficult UI direction, stronger implementation ideas, consequential review, or a second opinion. Keep the task narrow enough to conserve Claude usage.
- When Opus already supplied UI direction, default the independent double-check to a fresh Sonnet pass. Reuse Opus only when the review's consequence or complexity exceeds Sonnet's lane.
- Use **Fable 5 only when Semyon explicitly requests it in the current task**. Otherwise Opus is the highest Claude judgement lane available.
- Choose **Luna** for clear throughput work and the separate **Spark lane** for one low-intelligence repetitive unit. Do not give either ambiguous broad edits or final judgement.
- Treat persistence as ownership of the assigned outcome, not permission to bypass constraints, invent requirements, or widen scope. Codex keeps implementing, testing, diagnosing, and repairing until verified complete or concretely blocked.
- Raise effort only when uncertainty, consequence, or cross-cutting complexity warrants it. Move to xhigh/max only after a normal pass exposes a capability gap and state that gap first.
- Do not use **Fast Mode** for these lanes; their standard speed is sufficient. Spark remains a distinct model, not a Fast Mode setting.
- **Ultra is multi-agent orchestration, not another reasoning effort.** Use it only when independent parallel tracks outweigh coordination cost.
- A cross-model review should add a different hypothesis or judgement surface. Prefer one scoped Claude review of Codex work; do not duplicate the entire task merely because another model exists.

## delegation

Delegate only an independent, bounded unit that can run alongside useful lead work. Give each writer non-overlapping files or an independent worktree.

Provide:

```text
repo and branch/worktree:
one concrete outcome:
relevant facts and source of truth:
nearest local example:
constraints and non-goals:
minimum expected delta:
required verification:
stop condition:
return: files, behavior, checks, risks/blockers
```

The lead inspects the returned diff and reruns proportionate checks before accepting it. Treat delegated output as a patch candidate, not proof.

After one failed hypothesis, verify the premise against observed evidence before sending another workaround. Stop at the user's requested phase.
