# Agent skill fleet

This repository is the canonical source for **Semyon-owned shared agent skills**. Runtime skill directories are deployment targets, not the preferred place to edit shared skills.

## Current source layout

```text
home/.agents/skills/
  <skill-name>/SKILL.md
```

Each shared skill is linked from the relevant runtime package:

```text
claude/.claude/skills/<skill-name> -> ../../../home/.agents/skills/<skill-name>
codex/.codex/skills/<skill-name>   -> ../../../home/.agents/skills/<skill-name>
```

When those packages are deployed, their runtime targets are:

```text
~/.claude/skills/<skill-name>
~/.codex/skills/<skill-name>
```

## Scope

| Class | Canonical location | Deployment |
| --- | --- | --- |
| Shared, Semyon-owned skill | `home/.agents/skills/<name>/` | Link through both `claude` and `codex` packages when both runtimes should use it. |
| Claude-only skill | `claude/.claude/skills/<name>/` | Deploy only with the `claude` package. |
| Codex-only skill | `codex/.codex/skills/<name>/` | Deploy only with the `codex` package. |
| Machine-specific skill | `<host>/.agents/skills/<name>/` | Link only from that host's intended runtime package. |
| Runtime/vendor-managed skill | Leave in the runtime-managed location | Do not migrate into this repo unless ownership and update behaviour are understood. |

## Current shared skills

- `file-pr` — source material is the video passage at 15:04–17:45.
- `babysit-pr` — source material is the video passage at 10:18–12:24.
- `model-routing`, `ship-changes`, `skill-authoring`, and `visual-evidence` — existing Semyon-owned shared skills; each must retain its own provenance.

## Manual editing on the PC

Edit the source in the PC checkout, not `~/.claude/skills` or `~/.codex/skills`:

```bash
cd ~/dotfiles
$EDITOR home/.agents/skills/<skill-name>/SKILL.md
```

For changes to a skill already deployed as a symlink, the runtime sees the edit immediately. If adding a new shared skill, add its source and the appropriate links in both runtime packages, then use a dry-run before deployment:

```bash
stow --no-folding --simulate --verbose=2 claude codex
```

Do not force Stow over an existing runtime skill. Inspect ownership first; a native or vendor-managed skill may need to stay outside this repository.

## Migration rule

Do not bulk-move every installed skill. First classify it as shared-owned, runtime-specific, machine-specific, or vendor-managed. Migrate only the clear shared-owned skills, preserving source and deployment links together.
