# Claude Code Configuration

This package contains Claude Code configuration and instructions.

## Setup

```bash
cd ~/dotfiles
stow claude
```

This creates symlinks for:
- `~/.claude/CLAUDE.md` - Global Claude instructions
- `~/.claude/agents/` - Agent configurations (populate locally)
- `~/.claude/plugins/` - Plugin configurations (populate locally)

## Project-Specific Configuration

Each project can override the global CLAUDE.md by creating its own at the project root:

```
my-project/
├── CLAUDE.md          # Project-specific instructions
├── .claude/           # Optional: symlink to ~/.claude if needed
└── ...
```

## Sensitive Files

The following files are excluded from version control and must be managed locally:
- `.claude.json` - Credentials and auth tokens
- `.credentials.json` - API credentials
- `cache/`, `history.jsonl` - Runtime data

Never commit these files.

## Structure

```
~/.claude/
├── CLAUDE.md          # Sourced from dotfiles (symlinked)
├── .claude.json       # LOCAL: credentials and settings
├── agents/            # LOCAL: agent customizations
├── plugins/           # LOCAL: plugin configurations
├── cache/             # LOCAL: cache directory
└── ...
```
