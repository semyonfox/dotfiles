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

## Branch progress, 2026-08-20

- Migration worktree: `/home/semyon/dotfiles-skill-fleet-20260820` on `chore/skill-fleet-migration-20260820`. The original checkout remains untouched on its dirty branch.
- Restored the canonical `skill-fleet` and `unslop` sources, provider links for `unslop`, this handoff, and the revised fleet documentation to the migration branch.
- Moved the Codex package definition from `codex/.codex/skills` to `codex/.agents/skills`. The new links are relative and resolve to canonical `skills/` directories. The old package links were absolute and made GNU Stow reject the package even with an empty target.
- A clean-target Stow simulation succeeds. The live server dry-run correctly fails because `~/.agents` is a real unmanaged directory, and the old `~/.codex/skills` tree has mixed ownership. Do not deploy or delete those runtime paths yet.
- Read-only inventory: NAS has only Codex's managed `.system` directory. Laptop has shared `compress` and `find-skills`, plus untracked laptop-only `caveman`, `caveman-commit`, and `caveman-review` skills. Keep the latter three machine-specific until their source, trigger scope, and ownership are reviewed. The server Hermes corpus remains separate.

## Next work

1. Add a provider manifest only after the PC inventory is available and every candidate has an owner classification.
2. Build a safe audit/deploy helper or skill workflow. It must refuse to replace real directories, show a dry-run, and validate resolved `SKILL.md` files.
3. Define and validate the per-machine procedure for replacing the existing unmanaged `~/.agents` parent without using `stow --adopt` or forcing Stow.
4. Classify Hermes skills. Keep Hermes-only and vendor-managed skills out of the normal Claude/Codex allowlist.
5. Repair stale runtime documentation and links only after confirming their owners.
6. Run targeted validation, `./setup.sh --dry-run`, and provider-specific discovery checks.
7. Review the final diff. Do not commit or push unless explicitly requested.

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
