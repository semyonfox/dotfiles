---
name: model-routing
description: Use before delegating, orchestrating agents, escalating effort, requesting cross-model review, or picking Opus, Sonnet, Fable, Sol, Astra, or Luna — not whenever multiple models exist.

metadata:
  harnesses: [claude, codex, opencode, cursor, gemini, hermes]
---

# Model routing

Route by task shape, then billing. Claude is flat-rate and limit-bound; Codex is metered. Pick the smallest lane that fits and escalate only on observed evidence.

## billing (checked 2026-10-04)

- Claude Max $200/month flat. Fable 5.1 is capped at 50% of the weekly allowance and drains it faster.
- Codex Pro subscription until 2026-10-08, then credits billed at API list price.
- Past either date or if a plan changes, recheck before relying on this section.

## lanes

- **lead and default implementer:** Opus 5.5 (`claude-opus-5-5`). UI/product direction, implementation, review, second opinions.
- **fast bounded Claude work:** Sonnet 5.5 (`claude-sonnet-5-5`). Local UI, copy, focused review when speed matters. Verbose, so not cheaper on limits.
- **metered technical work:** GPT-6.1 Sol (`gpt-6.1-sol`). Bounded token-heavy or computer-use tasks where Codex tooling is better, or when Claude limits run out.
- **bulk mechanical work:** GPT-6 Luna (`gpt-6-luna`). Clearly specified extraction, classification, summaries, boilerplate. No product or architecture decisions.
- **request-only:** Fable 5.1 (`claude-fable-5-1`) and GPT-6 Astra (`gpt-6-astra`). Never auto-select, escalate to, or delegate to them without Semyon's explicit request in the current task.

Use full model IDs. Short aliases can resolve to older models: in T3, `opus` maps to Opus 5 and `sonnet` to Sonnet 5.

Do not use GPT-5.6, GPT-6 Sol, or Kimi K3. If a lane's model ID no longer appears in `orchestrator_capabilities`, flag it instead of guessing a substitute.

## effort

- Use medium by default and high for hard or consequential work.
- Use xhigh only as an escalation after a normal pass fails with a stated capability gap.
- Never use low, max, or ultrathink.
- Name the effort in every delegation: GPT-6.1 Sol defaults to low.
- Ultra/ultracode is multi-agent orchestration, not effort: use it only when independent parallel tracks outweigh coordination.
- Do not use Fast Mode.

## ownership

Separate the decision owner from the implementer; speed does not confer authority.

- Opus owns product, UI, and consequential defaults unless Fable was requested.
- Sol owns technical choices within an agreed outcome and persists through investigation, implementation, and verification until done or concretely blocked.
- Sonnet and Luna make only local, reversible choices and escalate ambiguity across their boundary.
- Cross-model review must add a distinct hypothesis or judgement surface; one scoped review beats duplicate work.

Read [references/benchmarks-2026-10-04.md](references/benchmarks-2026-10-04.md) when a numeric comparison or a price matters.

## delegation

Delegate only independent bounded work that can run alongside useful lead work; writers need non-overlapping files or independent worktrees. Provide:

```text
repo and branch/worktree:
model and effort:
one concrete outcome:
relevant facts and source of truth:
nearest local example:
constraints and non-goals:
required verification:
stop condition:
return: files, behavior, checks, risks/blockers
```

The lead inspects the returned diff and reruns proportionate checks: delegated output is a patch candidate, not proof. After one failed hypothesis, verify its premise against observed evidence before another workaround. Stop at the user's requested phase.
