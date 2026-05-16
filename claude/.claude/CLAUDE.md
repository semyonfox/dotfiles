# CLAUDE.md

global guidance. prefer running commands over trusting this file for anything derivable.

## user

Semyon Fox <semyon.fox@gmail.com>, Arch Linux, Hyprland/Wayland, Neovim (LazyVim), ghostty primary terminal. shells: bash (login), zsh. runtimes: Node via mise (use pnpm), Python via pyenv, Rust, Java 25.

## rules

- **git commits**: never mention ai, claude, or co-authorship. rebase workflow (pull --rebase, auto-stash on).
- **comments/docs/commits**: lowercase start, minimal, conversational, no emoji unless asked. identifiers keep their case (e.g. className).
- **dotfiles**: edit inside `~/dotfiles/{package}/`, never in `~` directly. remind me to run `stow <package>` after changes.
- **parallel agents**: one file per agent, no shared writes. spawn deliberately — each runs its own requests. use haiku/sonnet for simple subagents.
- **prefer editing existing files** over creating new ones.
- **token discipline**: `/compact` mid-task, `/clear` when switching tasks (long sessions cost even when cached). avoid 4+ concurrent sessions — they share one limit.
- **fast path**: for simple edits, inspect relevant files and implement directly. plan only for ambiguous, destructive, high-risk, or broad multi-file work. verify before claiming done. ask only when requirements are unclear or action is destructive. do not create implementation docs, staged confirmations, or checkpoint loops unless explicitly requested.

## where things live

- `~/dotfiles/` — stow-managed. packages mirror `$HOME`. run `stow <pkg>` to deploy. `lib/common.sh` has shared installer helpers. shell config split across `.bashrc`/`.zshrc` + `_aliases` + `_functions` — keep bash/zsh at parity.
- `~/code/{personal,university,compsoc,templates}/` — projects
- `~/obsidian/` — notes vault (Git + LFS). module dirs kebab-case. has its own CLAUDE.md when relevant.
- `~/projects/` — active workspace
- `~/Scripts/` — custom scripts

## derive, don't recite

to get current info, run commands instead of trusting embedded lists:

| need | command |
|---|---|
| aliases (70+ git, docker, etc.) | `alias \| grep <prefix>` or `cat ~/dotfiles/home/.zsh_aliases` |
| shell functions (mkcd, backup, extract, cleanup) | `cat ~/dotfiles/home/.zsh_functions` |
| directory tree | `ls ~` or `eza -T ~/code --level=2` |
| dotfiles install targets | `cat ~/dotfiles/setup.sh` |
| MCP servers / permissions | `cat ~/.claude/mcp.json ~/.claude/settings.json` |
| installed plugins | `ls ~/.claude/plugins/cache/` |
| OS/kernel/versions | `uname -a`, `node -v`, `python --version` |

## formatting defaults

- prettier + eslint for JS/TS
- 2-space indent: shell, json, yaml, toml, lua
- 4-space indent: everything else
- UTF-8, LF, trim trailing whitespace
