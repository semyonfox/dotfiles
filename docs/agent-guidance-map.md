# Guidance map

Keep repository instructions, shared working agreements, and reusable procedures in their respective source files.

| Source | Purpose |
| --- | --- |
| `AGENTS.md` | Repository layout, installer commands, constraints and verification rules. |
| `CLAUDE.md` | Loads the repository guide and adds a few Claude-specific notes. |
| `skills/AGENTS.md` | Shared personal working agreement. |
| `skills/<name>/SKILL.md` | A reusable procedure with a specific trigger. |
| `home/.agents/skills/` | Additional shared skill sources deployed by the home package. |

The global instruction files in `claude/.claude/` and `codex/.codex/` are symlinks to the shared agreement under `skills/`. Edit that agreement instead of editing deployed files. `skills/CLAUDE.md` also links to `AGENTS.md`.

Provider skill links live in their Stow packages. For example, `claude/.claude/skills/skill-authoring` and `codex/.agents/skills/skill-authoring` point to `skills/skill-authoring`.

Use `skill-authoring` when repeated work needs a durable procedure. A one-off correction usually belongs in the code or documentation. Keep global guidance brief and put repository-specific rules in the repository guide.

See [the skill layout](agent-skill-fleet.md) for provider links and deployment ownership. Inspect ownership and preview Stow changes before deploying new links.
