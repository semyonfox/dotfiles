---
name: skill-authoring
description: "Use when create, split, tune, or retire reusable agent skills from repeated real-world failures, workflows, or user corrections. Use when a user asks to make a skill, improve an agent instruction, turn a workflow into reusable guidance, or reduce repeated prompting."

metadata:
  harness: [claude, codex]
---

# Skill authoring

Skills are executable operating agreements: compact enough to load when needed, specific enough to improve repeated real work. Build them from observed friction, not imagined completeness.

## Core rule

Do not make a skill because a workflow sounds useful. Make or change one when at least one of these is true:

- the user repeats a workflow or correction;
- an agent repeatedly makes the same costly, unsafe, unclear, or wasteful mistake;
- a workflow needs exact prerequisites, commands, evidence, or stop conditions;
- a project has a local convention that a general agent cannot reliably infer.

A one-off task, generic preference, or instruction already covered by global/project guidance usually does **not** need a new skill.

## Workflow

1. **Inspect before writing.** Read relevant global/project instructions, existing skills, local examples, and—when useful—real agent/session history. Identify the exact trigger, desired outcome, failure pattern, safety boundary, and verification evidence.
2. **Choose the right instruction layer.**
   - Global guidance: durable collaboration rules across most work, such as inspect-before-edit, preserve WIP, or user questions being read-only.
   - Project `AGENTS.md` / `CLAUDE.md`: repository-specific architecture, terminology, invariants, commands, and known traps.
   - Skill: a recurring workflow requiring a procedure or specialised operational context.
   - Reference file: bulky commands, examples, inventories, or diagnostics that should not be loaded on every trigger.
3. **Check for overlap.** Extend or split an existing skill if it already owns the workflow. Create a new skill only if users will reasonably request it independently or its context should load independently.
4. **Write a trigger-first description.** The frontmatter `description` should say when to use the skill using likely user wording. It is an activation surface, not an exhaustive summary. Keep it self-contained and concise.
5. **Write the smallest reliable procedure.** Include only the instructions that change outcomes:
   - prerequisites and authoritative sources;
   - ordered safe steps and exact commands where non-obvious;
   - explicit safety boundaries and non-goals;
   - verification before claiming success;
   - a stop condition and precise blocker behavior.
6. **Use examples sparingly.** Add a bad/good pair when it teaches an otherwise ambiguous judgement, such as a useful PR title versus an implementation inventory. Do not turn a skill into a transcript or a style guide.
7. **Test the trigger and procedure.** Validate frontmatter, paths, referenced commands/scripts, and any real workflow that can safely be exercised. Confirm the skill is installed/linked where the intended agent runtime discovers skills.
8. **Refine from evidence.** After a real run, remove redundant prose, correct wrong assumptions, split overloaded workflows, and add only the minimal missing guardrail. Do not preserve stale or speculative rules.

## Structure

```md
---
name: lowercase-hyphenated-name
description: "Use when <recognisable user trigger>. <one-line outcome>."
---

# Human-readable name

One-sentence purpose and non-goal when needed.

## Workflow

1. Preconditions / source of truth.
2. Bounded operational steps.
3. Verification.

## Pitfalls

- Specific failure pattern → prevention.

## Stop conditions

- What requires user authority or should be reported as blocked.
```

Use `references/` for deep diagnostics, large tables, or templates. Keep the primary `SKILL.md` easy to scan.

## Quality gates

Before declaring a new or revised skill complete:

- [ ] The description contains the actual trigger words, not a generic capability label.
- [ ] Its scope is distinct from global/project guidance and existing skills.
- [ ] It states the source of truth, verification, and stop condition where relevant.
- [ ] It does not promise external/destructive actions without user authority.
- [ ] Examples, commands, paths, and referenced files exist and are current.
- [ ] The skill is available to each intended runtime or its installation/linking gap is reported.

## Anti-patterns

- **Transcript skill:** copying a video, chat, or docs dump instead of extracting a testable workflow.
- **Always-on manual:** stuffing a complete procedure into a description or global instructions.
- **One-off fossil:** saving temporary task status, a single incident, or stale infrastructure state.
- **Overloaded skill:** combining independently requested actions that should trigger separately.
- **Fake verification:** claiming a workflow is proven after only writing Markdown.
- **Rule accretion:** adding a broad prohibition after one ambiguous failure rather than diagnosing the actual cause.
