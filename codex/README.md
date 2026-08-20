# Codex package

Optional Codex global guidance and shared user-authored skills.

Deploy manually with:

```bash
stow --no-folding codex
```

This creates:

```text
~/.codex/AGENTS.md -> ~/dotfiles/codex/.codex/AGENTS.md
~/.agents/skills/<skill> -> ~/dotfiles/codex/.agents/skills/<skill>
```

This package intentionally does not belong to the default `server`, `pc`,
`laptop`, `nas`, or `minimal` profiles. Stow it only on devices where the same
Codex defaults and custom skills are wanted.

Tracked:

- `~/.codex/AGENTS.md` with public personal agent defaults
- shared Codex skills under `~/.agents/skills/`
- provider symlinks into the canonical `skills/` source tree

Not tracked:

- Codex auth, sessions, logs, task state, sqlite databases, memories, generated images, and plugin caches
- `.codex/skills/.system/`
- private `device-fleet` references such as `computers.md` and `t3-code.md`

## Migration safety

Codex discovers user skills from `~/.agents/skills`. The old
`~/.codex/skills` tree is not managed by this package.

Run a dry-run before deploying. Stop if `~/.agents`, `~/.agents/skills`, or a
target skill is a real directory or an unmanaged link. Do not use `stow --adopt`
or force Stow. Resolve ownership on that machine first, then migrate only the
confirmed shared skills.

Keep Claude and Codex global config split. This package does not install Claude
Fable routing into Codex globals.
