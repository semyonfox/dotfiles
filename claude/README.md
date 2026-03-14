# Claude Code Configuration

Global configuration for Claude Code (claude.ai/code) development environment. This package maintains consistent instructions, environment settings, and development workflows across all projects and machines.

## Overview

This package provides:
- **Global instructions** (`CLAUDE.md`) for consistent development practices
- **Environment setup** for Claude Code integration
- **Workflow standards** across all projects
- **MCP server configuration** for tool integrations
- **Development best practices** and conventions

## Setup

### Deploy with Stow

```bash
cd ~/dotfiles
stow claude
```

This creates symlinks:
```
~/.claude/CLAUDE.md → ~/dotfiles/claude/.claude/CLAUDE.md
~/.claude/settings.json → ~/dotfiles/claude/.claude/settings.json
~/.claude/mcp.json → ~/dotfiles/claude/.claude/mcp.json
```

### Verify Deployment

```bash
ls -la ~/.claude/
# Should show symlinks to dotfiles/claude/.claude/
```

## Configuration Files

### CLAUDE.md

Global instructions automatically loaded by Claude Code:

```
~/.claude/CLAUDE.md
├── System environment
├── Git conventions
├── Comments and documentation style
├── Agent behavior
├── Directory structure
├── Formatting and style guides
├── Common commands
└── Important patterns
```

All projects inherit these instructions unless overridden.

### settings.json (Local)

Claude Code user settings (NOT tracked in dotfiles):

```bash
~/.claude/settings.json
```

**Do NOT commit this file** - contains credentials and personal preferences.

### mcp.json (Local)

MCP (Model Context Protocol) server configuration:

```bash
~/.claude/mcp.json
```

Example structure:
```json
{
  "mcpServers": {
    "canvas": {
      "command": "/path/to/canvas-mcp-server",
      "args": ["--domain", "universityofgalway.instructure.com"]
    },
    "github": {
      "command": "gh",
      "args": ["api"]
    }
  }
}
```

## Project-Specific Override

Each project can provide its own instructions:

```
my-project/
├── CLAUDE.md          # Project-specific instructions (takes precedence)
├── .claude/           # Optional: local overrides
│   └── settings.json  # Project-specific settings
└── src/
    └── ...
```

### Project Instructions Example

```markdown
# My Project CLAUDE.md

## Architecture
[Project-specific architecture notes]

## Setup
[Project-specific setup]

## Naming Conventions
[Project-specific naming]

## Testing Strategy
[Project-specific test requirements]
```

## Global Instructions (CLAUDE.md)

### Key Sections

1. **System Environment**
   - OS: Arch Linux (bare metal, kernel 6.18+)
   - Desktop: Hyprland (Wayland)
   - Terminals: Ghostty, Kitty, Alacritty, Wezterm
   - Editor: Neovim (LazyVim)
   - Package managers: pnpm, pyenv, cargo

2. **Git Conventions**
   - Never mention AI/Claude in commits
   - Rebase workflow preferred
   - LF line endings (autocrlf = input)
   - Semantic commits

3. **Comments & Documentation**
   - Minimal, conversational style
   - Lowercase start (unless identifier)
   - No emojis (unless requested)
   - Clear and concise

4. **Agent Behavior**
   - Each agent handles one file at a time
   - Prefer editing over creating files
   - Follow dotfile stow structure

5. **Directory Structure**
   - `~/dotfiles/` - GNU Stow-managed dotfiles
   - `~/code/` - Development projects
   - `~/obsidian/` - Knowledge vault
   - `~/projects/` - Active workspace

6. **Formatting Standards**
   - 2-space indent: shell, JSON, YAML, TOML, Lua
   - 4-space indent: default for other languages
   - UTF-8, LF line endings
   - Prettier and ESLint for JS/TS

## MCP Servers

Model Context Protocol servers extend Claude's capabilities:

### Canvas LMS Integration

```json
{
  "canvas": {
    "command": "/home/semyon/projects/canvas-mcp/venv/bin/canvas-mcp-server",
    "args": ["--domain", "universityofgalway.instructure.com"]
  }
}
```

**Capabilities**:
- List courses
- Get course details
- List assignments
- Submit assignments
- Grade submissions
- Manage modules
- Discussion forums
- Announcements

## Sensitive Files

These files are intentionally excluded from version control:

```
~/.claude/
├── .claude.json       # Credentials and auth tokens
├── settings.json      # Personal settings and preferences
├── cache/             # Runtime cache
└── history.jsonl      # Conversation history
```

**NEVER commit these files.**

### .gitignore Entry

```
home/.claude/
.claude.json
.claude/settings.json
.claude/cache/
```

## Common Workflows

### Edit Global Instructions

```bash
nvim ~/.claude/CLAUDE.md
# or
nvim ~/dotfiles/claude/.claude/CLAUDE.md
```

### Update from Repository

```bash
cd ~/dotfiles
git pull
stow -R claude  # Force re-stow if needed
```

### Reset to Defaults

```bash
cd ~/dotfiles
stow -D claude  # Unlink
stow claude     # Re-link
```

### Check Active Configuration

```bash
# Show current instructions
cat ~/.claude/CLAUDE.md

# Show Claude Code settings
cat ~/.claude/settings.json  # (if exists)

# Show MCP configuration
cat ~/.claude/mcp.json  # (if exists)
```

## Environment Integration

### Shell Integration

Claude Code configuration works seamlessly with shell environment:

- Access to all shell aliases and functions
- Git configuration (from `home/.gitconfig`)
- Development tools (Node, Python, Rust, etc.)
- SSH keys and git credentials

### Project Integration

Claude automatically includes:
- Project `CLAUDE.md` if exists
- Project structure and files
- Local git history
- Project-specific environment variables

## Best Practices

### Instructions

1. **Be Explicit**: Detail what's important for this project
2. **Be Consistent**: Follow naming and style conventions
3. **Be Helpful**: Include setup instructions and gotchas
4. **Be Maintainable**: Update as project evolves

### Example Project CLAUDE.md

```markdown
# Project: My App

## Architecture
[Explain system design]

## Naming Conventions
- Components: PascalCase (React)
- Functions: camelCase
- Constants: UPPER_SNAKE_CASE
- CSS classes: kebab-case

## Setup
```bash
pnpm install
pnpm dev
```

## Testing
```bash
pnpm test      # Run tests
pnpm test:ui   # UI mode
```

## Common Tasks
- Development: `pnpm dev`
- Build: `pnpm build`
- Deploy: `pnpm deploy`

## Gotchas
- Node.js 20+ required
- Port 3000 must be free
- .env.local must be created
```

## Troubleshooting

### CLAUDE.md Not Loading

```bash
# Check symlink exists
ls -la ~/.claude/CLAUDE.md

# Check content
cat ~/.claude/CLAUDE.md | head -20

# Verify dotfiles deployed
cd ~/dotfiles && stow -S claude
```

### MCP Server Not Connecting

```bash
# Check mcp.json syntax
cat ~/.claude/mcp.json | jq .

# Verify command exists
which canvas-mcp-server

# Check permissions
ls -la /path/to/canvas-mcp-server
```

### Settings Not Persisting

**Note**: `~/.claude/settings.json` is local and not synced via dotfiles. Maintain separately or save to version control in a private repository.

## File Structure

```
claude/
└── .claude/
    ├── CLAUDE.md                 # Global instructions (symlinked)
    ├── settings.json             # (LOCAL - not tracked)
    ├── mcp.json                  # (LOCAL - not tracked)
    ├── agents/                   # (LOCAL - for agent configs)
    │   └── my-agent.md           # Custom agent instructions
    ├── plugins/                  # (LOCAL - for plugins)
    ├── cache/                    # (LOCAL - runtime cache)
    └── history.jsonl             # (LOCAL - conversation history)
```

## References

- **Claude Code Docs**: https://claude.ai/code
- **MCP Protocol**: https://modelcontextprotocol.io/
- **Canvas API**: https://canvas.instructure.com/doc/api/

## Related Packages

- **`home/`** - Shell configuration (aliases, functions, git config)
- **`hyprland/`** - Desktop environment configuration
- **All project CLAUDE.md files** - Project-specific instructions
