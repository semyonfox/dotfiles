# Codex package

Optional Codex global guidance and user-authored skills.

Deploy manually with:

```bash
stow --no-folding codex
```

This creates:

```text
~/.codex/AGENTS.md -> ~/dotfiles/codex/.codex/AGENTS.md
~/.codex/skills/<skill>/... -> ~/dotfiles/codex/.codex/skills/<skill>/...
```

This package intentionally does not belong to the default `server`, `pc`,
`laptop`, `nas`, or `minimal` profiles. Stow it only on devices where the same
Codex defaults and custom skills are wanted.

Tracked:

- `~/.codex/AGENTS.md` with public personal agent defaults
- non-system Codex skills under `~/.codex/skills/`
- source-like skill scripts, templates, and markdown references

Not tracked:

- Codex auth, sessions, logs, task state, sqlite databases, memories, generated images, and plugin caches
- `.codex/skills/.system/`
- private `device-fleet` references such as `computers.md` and `t3-code.md`

Keep Claude and Codex global config split. This package does not install Claude
Fable routing into Codex globals.
