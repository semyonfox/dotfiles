# CLAUDE.md

guidance for Claude Code across all projects.

## writing and git

- never mention ai, claude, or co-authorship in commit messages
- prefer rebase workflow (`pull --rebase`, auto-stash enabled)
- keep comments and docs minimal, conversational, and lowercase at the start unless using an identifier
- use LF, UTF-8, Prettier and ESLint for JS/TS; use 2-space indentation for shell, JSON, YAML, TOML, and Lua

## agent boundaries

- inspect before editing and verify before claiming success
- each parallel worker owns one file or an explicitly independent worktree; never allow shared writes
- for a repeated problem, propose the smallest durable instruction change, then keep it short
- no commits, pushes, PRs, deploys, destructive operations, or public messages unless the user explicitly asks

## model policy

Semyon uses the Codex $100/month plan.

- choose the Codex lane from task shape, not model prestige
- **Terra, medium:** default for interactive implementation, routine repo work, bounded refactors, and focused review; prefer it when the human will inspect each step or the change should remain deliberately small
- **Sol, medium:** use when Sol-level reasoning is useful but the work is short or uncertainty is moderate
- **Sol, high:** use for a difficult, well-scoped investigation, architecture decision, multi-step debugging, or autonomous bounded task likely to take more than about ten minutes; give it a concrete terminal condition and inspect its result
- **Sol xhigh/max/Ultra:** opt in only after a normal pass demonstrably lacks capability; state why the escalation is warranted because these modes can consume more time and usage while prolonging bad loops
- **Luna / Spark:** delegated only for independent extraction, classification, bulk transformation, title/branch generation, or one-file mechanical work; never give them broad edits, final judgment, or an ambiguous objective
- use Fable as lead only where its planning, product, security, API, or visual judgment materially beats Codex. Fable decides and verifies; Codex handles bounded execution

## task boundaries

Identify the requested phase and terminal condition before broad work.

- **plan:** inspect enough to produce the plan, then stop for approval unless implementation was explicitly authorized
- **implement:** change only the agreed scope, run the named verification, report it, then stop
- **review:** inspect only the named target and return findings; do not begin incidental refactors
- **PR work:** stop after the requested review round

Do not continue exploring, polishing, or expanding scope after the terminal condition. State the next sensible phase in one line instead of performing it.

## smallest sufficient change

Before editing, state the expected minimum delta: the files, behaviour, and verification that should be sufficient.

- prefer an existing local pattern over a new abstraction, subsystem, package, migration, or configuration layer
- do not rewrite adjacent code merely to make the patch feel cleaner
- add or update only tests that prove the requested behaviour or protect a demonstrated regression; do not generate speculative test matrices
- if the apparent fix grows beyond the stated minimum delta, stop and report what expanded, why, and the smallest viable alternative
- after one failed hypothesis, re-check the premise against observed evidence before inventing a workaround; do not pursue novel solutions to an unproven problem

## visual evidence

Gemini via Antigravity (`agy`) is the eyes for the lead model. For screenshot, UI, diagram, deck, or image-fidelity work, use it to describe what it actually sees: layout, visible text, colours, spacing, hierarchy, component states, icons, clipping, contrast, anomalies, and confidence. Feed those observations to the lead model as evidence.

Gemini does not decide taste, architecture, product direction, or implementation quality. Keep observed facts, discard or down-rank speculation, and let Claude/Fable/Codex make the decision.

Detailed Fable-to-Codex orchestration: `@~/.claude/fable-codex-orchestration.md`.

## environment

- targets: Ubuntu server/headless, CachyOS desktop/laptop, WSL2, Fedora, macOS
- package managers: pnpm/npm, pip/uv, cargo, apt/pacman as appropriate
- shell: Bash and Zsh, maintained through GNU Stow dotfiles
- editors: Neovim, Zed, VSCode/Cursor, JetBrains
- primary languages: Node.js/TypeScript, Python, Rust, Java
