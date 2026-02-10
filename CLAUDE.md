# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles managed with **GNU Stow** on a symlink-based model. Each top-level directory is a stow package that mirrors `$HOME`. The repo targets Arch Linux, Ubuntu, Fedora, macOS, and WSL2.

## Commands

```bash
# Deploy dotfiles (from repo root)
./setup.sh              # Interactive stow deployment with backup/rollback
./setup.sh --dry-run    # Preview what would be symlinked

# Install dependencies (OS-detected automatically)
./install-deps.sh

# Full interactive setup
./install.sh

# Switch default shell to zsh
./switch-to-zsh.sh

# Deploy a single stow package
stow home               # Symlink home/ contents into ~
stow claude             # Symlink claude/ contents into ~
```

## Architecture

**Stow packages** — each top-level directory is independently stowable:
- `home/` — shell configs (bash + zsh), git, tmux, wezterm, starship, terminal tools
- `claude/` — Claude Code global config (`~/.claude/CLAUDE.md`, agent/plugin placeholders)

**Installer scripts** share `lib/common.sh` for color output (`info`, `success`, `warn`, `error`), OS detection (`detect_os`, `is_wsl`), and error handling. All scripts use `set -e`.

**Shell config** is split into parallel bash/zsh files: `.bashrc`/`.zshrc` for main config, `_aliases` for aliases, `_functions` for functions. Changes to one shell should have an equivalent in the other.

## Conventions

- **Editorconfig**: LF endings, UTF-8, 4-space indent default, 2-space for shell/JSON/YAML/TOML/Lua
- **Script style**: `set -e`, use `lib/common.sh` helpers for output, handle errors with rollback
- **Cross-platform**: guard platform-specific code with OS detection; handle WSL2 as a distinct target
- **Stow-aware**: new config files go inside the appropriate package directory mirroring `$HOME` structure — never place files directly in `~`
- **No AI attribution in commits**
