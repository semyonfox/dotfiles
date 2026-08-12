# Skills

Write each shared skill once in `skills/<name>/SKILL.md`.

`AGENTS.md` and `CLAUDE.md` are the canonical global guidance alongside the skills. Runtime packages link shared skills into `~/.claude/skills/` and `~/.codex/skills/`; do not edit those deployed paths.

Use normal Markdown with only small metadata when it matters:

```yaml
---
name: example
description: Use when ...
metadata:
  harness: [claude, codex]
  platform: [linux]
---
```

Add `requires` only for a real prerequisite. Model/provider selection is runtime routing, not skill metadata.
