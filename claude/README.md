# Claude package

Tracked Claude Code global guidance.

Deploy with:

```bash
stow --no-folding claude
```

This creates:

```text
~/.claude/AGENTS.md -> ~/dotfiles/claude/.claude/AGENTS.md
~/.claude/CLAUDE.md -> ~/dotfiles/claude/.claude/CLAUDE.md
~/.claude/fable-codex-orchestration.md -> ~/dotfiles/claude/.claude/fable-codex-orchestration.md
```

Local Claude runtime state is intentionally not tracked:

```text
~/.claude/.claude.json
~/.claude/settings.json
~/.claude/mcp.json
~/.claude/cache/
~/.claude/history.jsonl
~/.claude/todos/
~/.claude/agents/
~/.claude/plugins/
```

Keep Claude and Codex global config split. This package is the source of truth for Claude/Fable guidance only; Codex defaults stay under `~/.codex` unless a dedicated Codex package is added later.
