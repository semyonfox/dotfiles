# Agent guidance map

> **Provenance — 2026-08-12:** This note is an operational map created by the assistant. It is **not** derived solely from the video. It uses local filesystem inspection and the assistant's general engineering judgement. No web sources were used for this change.
>
> The `skill-authoring` skill was inspired by the video’s core ideas (build skills from repeated failures, write trigger-first descriptions, keep instructions small, split overloaded skills, and refine from real use), but its detailed workflow, quality gates, structure, and anti-patterns include assistant-authored general guidance. Do not treat it as a verbatim or video-only extraction.

## The three layers

1. **Global agent instructions** tell an agent how to work with Semyon almost everywhere: preserve unrelated work, inspect before editing, do not implement when asked only to diagnose/review/plan, make the smallest sufficient change, verify it, and stop at the requested phase.
2. **Project instructions** explain a particular repository: architecture, invariants, commands, terminology, supported platforms, and local hazards. In this dotfiles repository, the root `AGENTS.md` is the project instruction file.
3. **Skills** hold a recurring procedure that should load only when its trigger applies: for example, shipping a PR or authoring a skill. A skill should not be a permanent dump of general advice.

## What the files here do

| Source file | Runtime / purpose | Current role |
| --- | --- | --- |
| `AGENTS.md` | Any agent working in `~/dotfiles` | Dotfiles project guide: GNU Stow model, package layout, cross-platform constraints, and a compact working agreement. |
| `CLAUDE.md` | Claude while working in `~/dotfiles` | Adds only Claude-specific notes on top of the root `AGENTS.md`. |
| `claude/.claude/AGENTS.md` | Global Claude guidance, deployed as `~/.claude/AGENTS.md` | Personal coding agreement across repositories. |
| `claude/.claude/CLAUDE.md` | Global Claude guidance, deployed as `~/.claude/CLAUDE.md` | Claude-only routing/delivery/visual-evidence additions. |
| `codex/.codex/AGENTS.md` | Global Codex guidance, deployed as `~/.codex/AGENTS.md` | Equivalent personal agreement and Codex-specific routing. This was not edited in the 2026-08-12 change because its write approval timed out. |
| `home/.agents/skills/skill-authoring/SKILL.md` | Shared source, linked into Claude and Codex skill roots | Helps convert repeated, evidenced workflows/failures into a small, trigger-first skill. |

`~/AGENTS.md` is a separate regular file for the home directory; it is **not** deployed by this dotfiles package and was not changed.

## What changed today

- Added a shared `skill-authoring` skill.
- Linked it live for Claude and Codex under `~/.claude/skills/skill-authoring` and `~/.codex/skills/skill-authoring`.
- Added one short pointer to that skill in the dotfiles root guidance and Claude global guidance.
- Did **not** rewrite the existing broad policies or deploy the full Stow packages, because the checkout already has unrelated changes and Stow’s dry run exposed a pre-existing skill-ownership conflict.

## How to use `skill-authoring`

Use it only when a workflow repeats or an agent repeatedly needs the same correction. It asks the agent to decide whether the right fix belongs in:

- global guidance,
- a project `AGENTS.md`/`CLAUDE.md`,
- a narrowly triggered skill, or
- a reference file.

Do not create skills for one-off tasks. Do not copy a whole generic skill library. Observe a real failure, make the smallest durable rule, test it, then trim it if it adds no value.

## Maintenance rule

Keep global files short. They load frequently, so they should contain stable collaboration defaults—not long procedures. Put project details in the project. Put repeatable procedures in a skill, with a short description that says **when** to load it.
