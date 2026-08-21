# AGENTS.md

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

## model routing

- use this section only when Claude Code is running on Fable 5 (`fable` / `claude-fable-5`) or the user explicitly asks for Fable-style orchestration.
- Fable is the scarce lead model for broad end-to-end coding work where planning, taste, API design, UI judgment, security review, and final implementation quality matter.
- keep Fable reasoning at `high` by default. avoid `x-high`, `max`, and `ultra code` unless there is a specific reason; they can burn the short Fable window without improving the result.
- glossary: `intelligence` = how hard a problem a model can handle unsupervised; `taste` = judgment for UI/UX, copy, API design, SDK shape, code quality, and product-facing details; `cost` = cost-efficiency/availability for Semyon's actual usage, not list price.
- current rankings, higher is better:

| model | cost | intelligence | taste |
|---|---:|---:|---:|
| gpt-5.5 | 9 | 8 | 5 |
| sonnet-5 | 5 | 5 | 7 |
| opus-4.8 | 4 | 7 | 8 |
| fable-5 | 2 | 9 | 9 |

- use `cost` only as a tiebreaker after intelligence and taste needs are met. OpenAI may rank high on cost because it is near-free for this account.
- cheaper or more plentiful models are support workers, not final arbiters. use them for bulk investigation, log reading, data analysis, spec digestion, mechanical edits, and independent review.
- prefer Codex/GPT-5.5 for token-heavy or computer-use-heavy support work: large logs, big PDFs/specs, screenshots, browser/app verification, simulator work, local machine interaction, bounded implementation, refactors, tests, and codebase search.
- Fable should feed Codex compact task cards with repo path, constraints, relevant knowledge, required verification, and expected return format. if a cheaper pass is below the bar, escalate or redo the work without asking.
- Codex output is a patch candidate. Fable/Claude must inspect the diff, rerun relevant checks, and fix or revert anything suspect before claiming success.
- when a problem repeats, propose the smallest durable instruction change that would prevent it, then trim it down.
- detailed playbook with exact commands: @~/.claude/fable-codex-orchestration.md

## where things live

- `~/dotfiles/` — stow-managed. packages mirror `$HOME`. run `stow <pkg>` to deploy. `lib/common.sh` has shared installer helpers. shell config split across `.bashrc`/`.zshrc` + `_aliases` + `_functions` — keep bash/zsh at parity.
- `~/code/{personal,university,compsoc,templates}/` — projects
- `~/obsidian/` — notes vault (Git + LFS). module dirs kebab-case. has its own AGENTS.md when relevant.
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
