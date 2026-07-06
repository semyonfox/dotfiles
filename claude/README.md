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
~/.claude/agents/*.md -> ~/dotfiles/claude/.claude/agents/*.md
~/.claude/agents/references/university-metadata-standard.md -> ~/dotfiles/claude/.claude/agents/references/university-metadata-standard.md
```

Local Claude runtime state is intentionally not tracked:

```text
~/.claude/.claude.json
~/.claude/settings.json
~/.claude/mcp.json
~/.claude/cache/
~/.claude/history.jsonl
~/.claude/todos/
~/.claude/plugins/
```

Tracked agent markdowns are source-like Claude subagents. Do not commit agent
crash logs, generated outputs, plugin caches, `mcp.json`, `settings.json`, or
credential files.

Keep Claude and Codex global config split. This package is the source of truth
for Claude/Fable guidance and Claude subagents only; Codex defaults live in the
optional `codex/` package.
