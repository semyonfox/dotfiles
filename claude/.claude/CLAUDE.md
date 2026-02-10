# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) as global instructions across all projects.

## Git

- Never mention AI, Claude, or co-authorship in commit messages
- Rebase workflow preferred (pull --rebase, auto-stash enabled)
- Line endings: `autocrlf = input` (LF in repo)

## Agent Behaviour

- Each parallel processing agent must only work on one file at a time, to keep context overloading likelihood to a minimum

## Environment

- **OS**: Windows with WSL2 (cross-platform dotfiles targeting Arch, Ubuntu, Fedora, macOS)
- **Package managers**: pnpm (Node.js), pip (Python), cargo (Rust)
- **Shell**: Bash and Zsh (parallel configs maintained via GNU Stow dotfiles)
- **Editors**: VSCode Insiders, Cursor, PyCharm (JetBrains)

## Languages & Runtimes

- Node.js 24+ / TypeScript (primary — pnpm workspaces for monorepos)
- Python 3.13+
- Rust 1.91+
- Java (JDK available)

## Formatting & Style

- Prettier and ESLint for JS/TS projects
- 2-space indent for shell, JSON, YAML, TOML, Lua
- 4-space indent default for everything else
- UTF-8, LF line endings, trim trailing whitespace
