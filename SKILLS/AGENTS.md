# Shared agent skills

This directory is the canonical source for shared skills.

- Write or edit a skill only at `skills/<name>/SKILL.md`.
- Runtime locations under `~/.claude/skills/` and `~/.codex/skills/` are deployed links; never edit them directly.
- Keep a skill's frontmatter small: `name`, a trigger-first `description`, and only real compatibility/prerequisite metadata.
- Model/provider selection belongs to runtime routing, not individual skill files.
