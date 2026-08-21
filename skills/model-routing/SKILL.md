---
name: model-routing
description: Use before delegating, orchestrating agents, escalating effort, requesting cross-model review, or picking Sol, Terra, Luna, Spark, Opus, Sonnet, or Fable — not whenever multiple models exist.

metadata:
  harness: [claude, codex]
---

# Model routing

Route by task shape and personal intelligence, taste, and effective-cost scores—not prestige. Intelligence is unsupervised problem solving; taste covers judgement, interaction, UI/UX, copy, API/SDK design, code quality, and product detail; cost is value/availability under Semyon's subscriptions and limits (including pricing and thinking efficiency), where higher is better, not API list price.

| model and access | intelligence | cost | taste | route when |
| --- | ---: | ---: | ---: | --- |
| **GPT-5.6 Terra** (`gpt-5.6-terra`) | 8 | 10 | 6 | Default interactive implementation, bounded refactors, focused review. |
| **GPT-5.6 Sol** (`gpt-5.6-sol`) | 9 | 9 | 6 | Difficult bounded investigation, architecture, debugging, autonomous execution. |
| **GPT-5.6 Luna** (`gpt-5.6-luna`) | 6 | 10 | 5 | Clear high-volume transformation and tightly specified mechanical work. |
| **Claude Opus 5** (`claude-opus-5`) | 9 | 3 | 9 | Scarce UI/product lead, implementation ideas, difficult review, second opinion. |
| **Claude Sonnet 5** (`claude-sonnet-5`) | 6 | 4 | 7 | Scarce bounded UI implementation/review, copy, product-facing help. |
| **Claude Fable 5** (`claude-fable-5`) | 10 | 1 | 10 | Explicit-request-only frontier judgement and final calls. |

Reject a model below either required intelligence or taste; among survivors choose the smallest sufficient model, using cost only to break equal-fit ties. Never trade required intelligence or taste for cost.

Claude is the scarce UI/taste specialist; GPT-5.6 Codex owns routine implementation and technical execution. Use focused Claude passes, not duplicate routine work. Fable may be selected, escalated to, or delegated only on Semyon's explicit request in the current task; otherwise Opus is the highest Claude judgement lane. Keep Kimi K3 inactive unless Semyon explicitly re-enables it.

**Spark** (`gpt-5.3-codex-spark`) is outside the matrix: one low-intelligence, bounded, independent repetitive unit (summaries, extraction, classification, boilerplate cleanup, compact factual reports) only—not broad edits or final judgement. The lead verifies and synthesises.

## Ownership and orchestration

Separate decision owner from implementer; speed does not confer authority.

| lane | authority and contract |
| --- | --- |
| **Fable 5** | After explicit request only: resolve frontier/architecture/taste/final-call escalations, frame outcome, and synthesise. |
| **Opus 5** | UI/product direction, strong recommendations, consequential defaults when Fable was not requested; ideas, ambiguous UI planning, Codex review, or direct work when judgement and code cannot separate. |
| **Sol** | Technical choices within agreed outcome/constraints; persist through difficult investigation, debugging, refactors, implementation, and verification until complete or concretely blocked. |
| **Terra** | Local technical choices within clear acceptance criteria; routine features, fixes, tests, and focused review with proportionate verification. |
| **Luna** | Clearly specified volume only; no product, architecture, or ambiguous cross-file decisions; escalate ambiguity. |
| **Sonnet 5** | Reversible local UI/copy/UX choices, not final authority; bounded implementation/review when a focused Claude pass is worth scarce allowance. |
| **Spark** | Literal microtask only; compact structured output for lead verification. |

Use Sonnet for bounded UI work and Opus for higher ambiguity, consequence, taste, implementation ideas, or second opinions. After Opus direction, use a fresh Sonnet double-check by default; reuse Opus only if the review itself exceeds Sonnet's lane. Let Claude implement when judgement and code are inseparable; otherwise have it frame/review and give bulk execution to Codex. Workers escalate ambiguity across their boundary.

Read [references/benchmarks-2026-07-31.md](references/benchmarks-2026-07-31.md) if numeric comparison, current price, or availability matters; recheck official sources if it is over 30 days old or a model name no longer resolves.

## Decisions

- Start normal execution at **Terra medium**; use **Sol medium/high** for more intelligence without high taste needs.
- Use Fable only on an explicit current-task request; Luna for clear throughput and Spark for a separate low-intelligence repetitive unit—never ambiguous broad edits or final judgement.
- Persistence means owning the assigned outcome, not bypassing constraints, inventing requirements, or widening scope: Codex implements, tests, diagnoses, and repairs until verified complete or concretely blocked.
- Raise effort only for uncertainty, consequence, or cross-cutting complexity. Move to xhigh/max only after a normal pass shows a stated capability gap. Do not use **Fast Mode**; Spark is a model, not a Fast Mode setting. **Ultra** is multi-agent orchestration, not reasoning effort; use it only when independent parallel tracks outweigh coordination.
- Cross-model review must add a distinct hypothesis or judgement surface; prefer one scoped Claude review of Codex work.

## Delegation

Delegate only independent bounded work that can run alongside useful lead work; writers need non-overlapping files or independent worktrees. Provide:

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

The lead inspects the returned diff and reruns proportionate checks: delegated output is a patch candidate, not proof. After one failed hypothesis, verify its premise against observed evidence before another workaround. Stop at the user's requested phase.
