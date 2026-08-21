# AGENTS.md

global local-context guidance. Derive live facts with commands rather than trusting this file.

## user environment

Semyon Fox uses Arch Linux with Hyprland/Wayland, Neovim (LazyVim), Ghostty, bash for login, zsh, Node through mise with pnpm, Python through pyenv, Rust, and Java 25.

## local rules

- git commits never mention ai, claude, or co-authorship; prefer rebase workflow
- comments, docs, and commits are minimal, conversational, lowercase at the start, and emoji-free unless asked
- edit dotfile sources under `~/dotfiles/{package}/`, never `~` directly; keep bash/zsh equivalents aligned and remind Semyon to run `stow <package>` when needed
- prefer an existing file to a new one
- inspect before editing, verify before claiming success, and ask only when requirements are unclear or an action is destructive
- parallel agents need independent file ownership or worktrees; do not use four or more hungry sessions by default

## shared AI policy

`@~/.claude/CLAUDE.md` is the canonical full policy for model choice, stop points, visual evidence, and Fable/Codex orchestration. If it is not loaded: use Terra medium for routine human-steered work; use Sol high only for difficult, well-scoped autonomous work with a terminal condition; delegate Luna/Spark only for narrow mechanical units.

## where things live

- `~/dotfiles/` — Stow packages; shared installer helpers are in `lib/common.sh`
- `~/code/{personal,university,compsoc,templates}/` — projects
- `~/obsidian/` — Git + LFS notes vault; read its local `AGENTS.md` when present
- `~/projects/` — active workspace
- `~/Scripts/` — custom scripts

## formatting defaults

- Prettier and ESLint for JS/TS
- 2-space indentation for shell, JSON, YAML, TOML, and Lua; 4-space default otherwise
- UTF-8, LF, no trailing whitespace
