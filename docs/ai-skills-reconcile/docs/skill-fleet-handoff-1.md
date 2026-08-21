# Skill fleet handoff

## Objective

Finish the shared skill deployment model for Claude Code, Codex, and selected Hermes skills. Keep one canonical skill tree, expose skills with symlinks, and avoid copying or bulk-importing provider/vendor collections.

## Repository

- Git remote: `git@github.com:semyonfox/dotfiles.git`
- Web repository: https://github.com/semyonfox/dotfiles
- Checkout: `/home/semyon/dotfiles`
- Canonical skills: `/home/semyon/dotfiles/skills/`
- Claude package: `/home/semyon/dotfiles/claude/`
- Codex package: `/home/semyon/dotfiles/codex/`
- Hermes package: `/home/semyon/dotfiles/hermes/`
- Setup script: `/home/semyon/dotfiles/setup.sh`
- Main documentation: `/home/semyon/dotfiles/docs/agent-skill-fleet.md`
- Operational skill: `/home/semyon/dotfiles/skills/skill-fleet/SKILL.md`

## Intended layout

```text
dotfiles/skills/<name>/SKILL.md       # source of truth
dotfiles/claude/.claude/skills/<name> # symlink
dotfiles/codex/.agents/skills/<name>  # symlink
dotfiles/hermes/.hermes/skills/<name> # selected Hermes links only
```

Runtime targets:

```text
~/.claude/skills/<name>
~/.agents/skills/<name>
~/.hermes/skills/<name>
```

## Work already done

- `unslop` was added at `/home/semyon/dotfiles/skills/unslop/`.
- It is linked into the current Claude and Codex package layers.
- Its source preserves the pinned pstack content and includes provider metadata plus Codex UI metadata.
- The current worktree already contains substantial unrelated user changes. Do not reset, clean, or overwrite them.
- The existing `codex/.codex/skills` layout and some old documentation/runtime links still need careful migration. Do not assume every existing link is owned by Stow.

## Next work

1. Inspect `git status`, current symlink targets, and Stow ownership.
2. Decide whether to add a small provider manifest under the skills area.
3. Update the Codex package from `.codex/skills` to `.agents/skills`, preserving compatibility only where live tooling still requires it.
4. Build a safe audit/deploy helper or skill workflow. It must refuse to replace real directories, show a dry-run, and validate resolved `SKILL.md` files.
5. Classify Hermes skills. Keep Hermes-only and vendor-managed skills out of the normal Claude/Codex allowlist.
6. Repair stale documentation and links only after confirming their owners.
7. Run targeted validation, `./setup.sh --dry-run`, and provider-specific discovery checks.
8. Review the final diff. Do not commit or push unless explicitly requested.

## Constraints

- Edit canonical skill content only under `skills/`.
- Use symlinks for provider exposure.
- Preserve `SKILL.md` portability. Use `agents/openai.yaml` for Codex-specific UI/invocation settings.
- Apply `unslop` to documentation and handoff text.
- Use `/home/semyon/.codex/skills/.system/skill-creator/SKILL.md` when creating or substantially changing a skill.
- Use the current official provider documentation when deciding discovery paths:
  - https://developers.openai.com/codex/skills
  - https://code.claude.com/docs/en/slash-commands
  - https://agentskills.io/home
