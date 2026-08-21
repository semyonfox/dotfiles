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
- A clean-target Stow simulation succeeds. The live server dry-run refuses the legacy state: `~/.agents` is a dangling old Stow link and the old Claude/Codex locations mix links with real directories. Do not force Stow over those paths; move only inventoried legacy skill entries to a recoverable backup, then create the provider links.
- Read-only inventory: NAS has only Codex's managed `.system` directory. Laptop has shared `compress` and `find-skills`, plus untracked laptop-only `caveman`, `caveman-commit`, and `caveman-review` skills. Keep the latter three machine-specific until their source, trigger scope, and ownership are reviewed. The server Hermes corpus remains separate.

## Mini checklist, 2026-08-20

Legend: `x` means the canonical source and declared provider link have been checked. `-` means the skill does not declare that provider.

| Skill | Claude | Codex | Notes |
| --- | :---: | :---: | --- |
| agent-friendly-sites | - | x | |
| babysit-pr | x | x | |
| better-typography | - | x | |
| claude-second-opinion | - | x | |
| compress | x | - | |
| device-fleet | x | x | PC edit reviewed: Claude support added. |
| file-pr | x | x | Review its interaction with `ship-changes` before the next PR workflow revision. |
| find-skills | x | - | |
| flatmmo-userscript-handoff | - | x | |
| html-communication | x | x | PC edit reviewed: Seol publishing remains user-requested. |
| model-routing | x | x | |
| seol | x | x | PC edit reviewed: accountless credential wording retained; sensitive content blocks publishing. |
| seol-read | x | x | PC edit reviewed: exact shell fetch, no `/raw` rewrite. |
| ship-changes | x | x | |
| skill-authoring | x | x | |
| skill-fleet | x | x | Provider links added during this pass. |
| unslop | x | x | |
| visual-evidence | x | x | |
| web-perf | x | x | |

### PC edits

- [x] `device-fleet`: declare Claude and Codex support.
- [x] `html-communication`: preserve the human-document workflow; publish only on an explicit share request and let `seol` own publishing details.
- [x] `seol-read`: fetch the supplied URL directly with bounded shell `curl`; no browser, search, or `/raw` rewrite.
- [x] `seol`: declare Claude and Codex support, retain the sensitive-content stop, and name the accountless publisher credential accurately.

### Deployment status

- [x] Server and PC now expose 15 Claude and 17 Codex skills each. Every remaining live provider link resolves through the migration worktree's provider link to `skills/<name>/SKILL.md`.
- [x] The legacy non-system `~/.codex/skills` entries were moved out, leaving only Codex-managed `.system` content. Codex now reads `~/.agents/skills`, its documented user-level discovery location.
- [x] Existing provider entries were moved, not deleted, into dated directories under `~/.local/state/skill-fleet-migration-20260820/` on each machine before links were recreated.
- [x] The PC's four in-progress edits are also preserved in the named Git stash `skill-fleet-pc-edits-before-a3d43e2`; the reviewed versions are committed on this branch.
- [ ] Full-package Stow remains intentionally disabled for these two packages because unrelated live Claude configuration files are outside this migration. Future deployments must use the checked per-skill migration procedure or first reconcile those non-skill files; never force or adopt Stow over them.

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
