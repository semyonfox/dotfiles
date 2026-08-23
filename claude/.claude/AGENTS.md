# Personal coding agreements

- inspect the branch, worktree, and uncommitted changes before editing; preserve unrelated work
- use a scoped branch or independent worktree when concurrent or unrelated writes overlap
- prefer rebase workflow (`pull --rebase`, auto-stash enabled)
- never mention AI, Claude, Codex, or co-authorship in commits
- keep comments and docs minimal and conversational; use UTF-8 and LF
- follow repository formatters and linters; absent project rules, use 2 spaces for shell, JSON, YAML, TOML, and Lua
- edit dotfile sources under `~/dotfiles/<package>/`, not deployed files under `~`
- inspect before editing, verify before claiming success, and stop at the requested phase
- answer, diagnose, review, and plan without implementing unless change is requested
- for change requests, make the smallest sufficient local change and run relevant safe checks
- do not expand into unrelated cleanup, migrations, dependencies, or configuration

Environment: Ubuntu server/headless, CachyOS desktop/laptop, WSL2, Fedora, and macOS; Bash and Zsh; pnpm/npm, uv/pip, Cargo, apt/pacman as appropriate.
