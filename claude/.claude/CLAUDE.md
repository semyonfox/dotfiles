# CLAUDE.md

guidance for claude code across all projects

## git

- never mention ai, claude, or co-authorship in commit messages
- rebase workflow preferred (pull --rebase, auto-stash enabled)
- line endings: `autocrlf = input` (LF in repo)

## comments & documentation

- keep comments minimal and conversational, no unnecessary punctuation
- lowercase at start unless referring to identifiers (e.g. className)
- avoid emoji unless specifically requested
- this applies to code comments, commit messages, and documentation

## agent behaviour

- each parallel processing agent must only work on one file at a time

## environment

- os: Windows with WSL2 (cross-platform dotfiles targeting Arch, Ubuntu, Fedora, macOS)
- package managers: pnpm (Node.js), pip (Python), cargo (Rust)
- shell: Bash and Zsh (parallel configs maintained via GNU Stow dotfiles)
- editors: VSCode Insiders, Cursor, PyCharm (JetBrains)

## languages & runtimes

- Node.js 24+ / TypeScript (primary — pnpm workspaces for monorepos)
- Python 3.13+
- Rust 1.91+
- Java (JDK available)

## formatting & style

- Prettier and ESLint for JS/TS projects
- 2-space indent for shell, JSON, YAML, TOML, Lua
- 4-space indent default for everything else
- UTF-8, LF line endings, trim trailing whitespace
