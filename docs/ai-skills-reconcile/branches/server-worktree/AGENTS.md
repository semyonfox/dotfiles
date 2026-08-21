# Dotfiles repository

Personal dotfiles managed with GNU Stow. Each top-level package mirrors `$HOME`; targets include Arch/CachyOS, Ubuntu, Fedora, macOS, and WSL2.

## commands

```bash
./setup.sh --dry-run    # preview the normal deployment
./setup.sh              # interactive deployment with backup/rollback
./install-deps.sh       # install OS-detected dependencies
./install.sh            # full interactive setup
stow --no-folding home  # deploy one package
```

## layout

- `home/` — shell, Git, tmux, terminal tools, shared user files and agent skills
- `claude/` — Claude Code global instructions and Claude-specific links
- `codex/` — Codex global instructions and Codex-specific links
- `lib/common.sh` — installer output, OS detection, WSL detection, and error helpers

Shell configuration is maintained in parallel Bash and Zsh files. Keep equivalent aliases and functions aligned.

## constraints

- edit package sources in this repository, never deployed files in `$HOME`
- preserve unrelated changes in this dirty worktree
- prefer existing package and installer patterns over new abstractions
- guard platform-specific behavior and treat WSL2 as a distinct target
- use UTF-8 and LF; default to 4 spaces, with 2 spaces for shell, JSON, YAML, TOML, and Lua
- scripts use `set -e` or stricter and reuse `lib/common.sh` where applicable
- add only tests or checks that prove requested behavior or a demonstrated regression
- never add AI attribution to commits

## agent guidance

- inspect the branch/worktree and preserve unrelated changes before editing
- treat questions, reviews, diagnosis, and planning as read-only unless a change is requested
- for a requested change, make the smallest sufficient edit, verify it with proportionate checks, and stop at the requested phase
- do not widen work into unrelated cleanup, migrations, dependencies, configuration, or broad test runs without a demonstrated need
- use `skill-authoring` when converting repeated failures, corrections, or workflows into reusable agent skills; keep descriptions trigger-first, global guidance compact, and repository operations in project guidance
