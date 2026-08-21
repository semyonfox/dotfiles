# Agent skill fleet

This repository is the canonical source for Semyon-owned shared skills. Runtime skill directories are deployment targets, not places to edit shared skill contents. The companion operational skill is [`skills/skill-fleet/SKILL.md`](../skills/skill-fleet/SKILL.md).

## Current source layout

```text
skills/
  <skill-name>/SKILL.md
```

Each shared skill is linked from the relevant provider package:

```text
claude/.claude/skills/<skill-name>  -> canonical skills/<skill-name>
codex/.agents/skills/<skill-name>   -> canonical skills/<skill-name> (planned)
hermes/.hermes/skills/<skill-name>  -> canonical skills/<skill-name>
```

When those packages are deployed, their runtime targets are:

```text
~/.claude/skills/<skill-name>
~/.agents/skills/<skill-name>
~/.hermes/skills/<skill-name>
```

The repository still contains an older `codex/.codex/skills` layout. Treat it as a migration target, not the desired long-term location. Codex's current documented user-level discovery path is `~/.agents/skills`.

## What belongs in a skill directory

`SKILL.md` is the required entrypoint. Keep it focused on the workflow and its trigger description. Add supporting files only when they have a clear purpose:

- `references/` for detailed material loaded only when needed.
- `scripts/` for repeatable or deterministic operations.
- `assets/` and `templates/` for files used in generated output.
- `tests/` for validation of a complex skill.
- `agents/openai.yaml` for Codex-specific UI and invocation metadata.

Portable compatibility information can live in `SKILL.md` frontmatter. That metadata describes the skill; it does not create provider links. Provider exposure remains a repository/package concern.

## Scope

| Class | Canonical location | Deployment |
| --- | --- | --- |
| Shared, Semyon-owned skill | `skills/<name>/` | Link through each provider package that should use it. |
| Claude-only skill | `claude/.claude/skills/<name>/` | Deploy only with the `claude` package. |
| Codex-only skill | `codex/.agents/skills/<name>/` | Deploy only with the `codex` package. |
| Machine-specific skill | `<host>/.agents/skills/<name>/` | Link only from that host's intended runtime package. |
| Runtime/vendor-managed skill | Leave in the runtime-managed location | Do not migrate into this repo unless ownership and update behaviour are understood. |

## Current shared skills

- `file-pr` — source material is the video passage at 15:04–17:45.
- `babysit-pr` — source material is the video passage at 10:18–12:24.
- `model-routing`, `ship-changes`, `skill-authoring`, and `visual-evidence` — existing Semyon-owned shared skills; each must retain its own provenance.

## Manual editing on the PC

Edit the source in the checkout, not the live provider directories:

```bash
cd ~/dotfiles
$EDITOR skills/<skill-name>/SKILL.md
```

For changes to a skill already deployed as a symlink, the runtime sees the edit immediately. If adding a new shared skill, add its source and the appropriate links in both runtime packages, then use a dry-run before deployment:

```bash
stow --no-folding --simulate --verbose=2 claude codex hermes
```

Do not force Stow over an existing runtime skill. Inspect ownership first; a native or vendor-managed skill may need to stay outside this repository. Claude and Codex support symlinked skill directories, so copying is unnecessary.

## Migration rule

Do not bulk-move every installed skill. First classify it as shared-owned, runtime-specific, machine-specific, Hermes-only, or vendor-managed. Migrate only the clear shared-owned skills, preserving the source and deployment links together.

## Overall plan

1. Keep `/home/semyon/dotfiles/skills/` as the one editable source tree.
2. Add a provider allowlist or manifest before automating link creation.
3. Move the Codex package toward `.agents/skills` and remove stale `.codex/skills` assumptions after checking live ownership.
4. Keep the Hermes corpus separate and link only selected skills into normal development providers.
5. Add a small audit/deploy helper that creates links, refuses to overwrite real directories, validates targets, and runs Stow dry-runs.
6. Re-scan all live provider directories before calling the migration complete.

## Handoff

The next agent should start with [`docs/skill-fleet-handoff.md`](skill-fleet-handoff.md), inspect the current dirty worktree, and preserve unrelated changes. The repository remote is `git@github.com:semyonfox/dotfiles.git`.
