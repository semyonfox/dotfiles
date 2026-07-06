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
- when a problem repeats, propose the smallest durable instruction change that would prevent it, then trim it down

## model routing

- use this section only when Claude Code is running on Fable 5 (`fable` / `claude-fable-5`) or the user explicitly asks for Fable-style orchestration.
- Fable is the scarce lead model for broad end-to-end coding work where planning, taste, API design, UI judgment, security review, and final implementation quality matter.
- keep Fable reasoning at `high` by default. avoid `x-high`, `max`, and `ultra code` unless there is a specific reason.
- glossary: `intelligence` = how hard a problem a model can handle unsupervised; `taste` = judgment for UI/UX, copy, API design, SDK shape, code quality, and product-facing details; `cost` = cost-efficiency/availability for Semyon's actual usage, not list price.
- current rankings, higher is better:

| model | cost | intelligence | taste |
|---|---:|---:|---:|
| gpt-5.5 | 9 | 8 | 5 |
| sonnet-5 | 5 | 5 | 7 |
| opus-4.8 | 4 | 7 | 8 |
| fable-5 | 2 | 9 | 9 |

- use `cost` only as a tiebreaker after intelligence and taste needs are met. OpenAI may rank high on cost because it is near-free for this account.
- use cheaper or more plentiful models as support workers for bulk investigation, log reading, data analysis, spec digestion, mechanical edits, and independent review.
- prefer Codex/GPT-5.5 for token-heavy or computer-use-heavy support work: large logs, big PDFs/specs, screenshots, browser/app verification, simulator work, local machine interaction, bounded implementation, refactors, tests, and codebase search.
- Fable should feed Codex compact task cards with repo path, constraints, relevant knowledge, required verification, and expected return format. if a cheaper pass is below the bar, escalate or redo the work without asking.
- Codex output is a patch candidate. Fable/Claude must inspect the diff, rerun relevant checks, and fix or revert anything suspect before claiming success.
- detailed playbook with exact commands: @~/.claude/fable-codex-orchestration.md

## environment

- os targets: Ubuntu server/headless, CachyOS desktop/laptop, WSL2, Fedora, macOS
- package managers: pnpm/npm (Node.js), pip/uv (Python), cargo (Rust), apt/pacman depending on host
- shell: Bash and Zsh (parallel configs maintained via GNU Stow dotfiles)
- editors: Neovim, Zed, VSCode/Cursor, JetBrains tools

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
