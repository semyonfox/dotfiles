---
name: skill-fleet
description: Explain, audit, and safely wire shared skills from this dotfiles repository into Claude Code, Codex, and selected other providers.
metadata:
  harnesses: [claude, codex, opencode, cursor]
  compatibility: Claude Code and Codex CLI on Semyon's dotfiles-managed machines.
  category: maintenance
  tier: core
---

# Skill fleet

Use this skill when setting up, auditing, or changing the shared skill layout in `/home/semyon/dotfiles`.

## Source of truth

Edit shared skills only here:

```text
/home/semyon/dotfiles/skills/<skill-name>/SKILL.md
```

The directory may contain optional supporting files such as `references/`, `scripts/`, `assets/`, `templates/`, `tests/`, and Codex UI metadata at `agents/openai.yaml`. Do not copy those files into runtime directories.

## Provider exposure

Provider packages contain symlinks, not second copies of skill contents:

```text
/home/semyon/dotfiles/claude/.claude/skills/<skill-name>
/home/semyon/dotfiles/codex/.agents/skills/<skill-name>  # planned Codex layout
/home/semyon/dotfiles/hermes/.hermes/skills/<skill-name>
```

After Stow deployment, the intended runtime locations are:

```text
~/.claude/skills/<skill-name>
~/.agents/skills/<skill-name>
~/.hermes/skills/<skill-name>
```

Hermes is a separate, larger collection. Expose only an explicit allowlist of Hermes skills to normal development workflows.

## Metadata rules

Keep portable metadata in `SKILL.md`:

```yaml
---
name: skill-name
description: Say what the skill does and when it should trigger.
metadata:
  harnesses: [claude, codex]
  compatibility: Claude Code and Codex CLI.
---
```

The `metadata` map describes the skill for repository tooling. It does not itself install or route the skill.

Put Codex-specific interface and invocation settings in `agents/openai.yaml`. Use Claude-specific frontmatter only when the shared behaviour cannot express the requirement. Keep the main skill body portable where possible.

## Safe setup workflow

When wiring a skill:

1. Inspect the source and each provider target before editing.
2. Confirm the provider is supported by the skill metadata and the deployment plan.
3. Create a symlink from the provider package to the canonical source. Never overwrite a real runtime directory.
4. Check that the symlink resolves to `SKILL.md` and that supporting files resolve too.
5. Run a Stow dry-run before applying changes.
6. Deploy only the intended provider package.
7. Re-scan the live provider directories and report broken links, conflicts, and unmanaged copies.

Use the provider's documented discovery path. Claude follows skill-directory symlinks. Codex also follows symlinked skill folders and currently documents `~/.agents/skills` as its user-level location. Do not assume that an arbitrary source directory will be scanned directly.

## Repository

Remote: [semyonfox/dotfiles](https://github.com/semyonfox/dotfiles)

Relevant local paths:

- Canonical skills: `/home/semyon/dotfiles/skills/`
- Claude Stow package: `/home/semyon/dotfiles/claude/`
- Codex Stow package: `/home/semyon/dotfiles/codex/`
- Hermes Stow package: `/home/semyon/dotfiles/hermes/`
- Fleet notes: `/home/semyon/dotfiles/docs/agent-skill-fleet.md`
- Setup entrypoint: `/home/semyon/dotfiles/setup.sh`

Do not bulk-migrate vendor-managed or Hermes-only skills. Classify them first, then expose only the skills that are useful for the provider and normal development work.
