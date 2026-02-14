# CLAUDE.md

guidance for claude code across all projects

## git

- never mention ai, claude, or co-authorship in commit messages
- rebase workflow preferred (pull --rebase, auto-stash enabled)
- line endings: `autocrlf = input` (LF in repo)
- diff algorithm: histogram with color-moved
- rerere enabled (record/reuse conflict resolutions)
- branch sorting: by commit date (newest first)

## comments & documentation

- keep comments minimal and conversational, no unnecessary punctuation
- lowercase at start unless referring to identifiers (e.g. className)
- avoid emoji unless specifically requested
- this applies to code comments, commit messages, and documentation

## agent behaviour

- each parallel processing agent must only work on one file at a time
- prefer editing existing files over creating new ones
- when working with dotfiles, make changes inside `~/dotfiles/{package}/` structure, never directly in `~`
- after dotfiles changes, remind user to run `stow <package>` to deploy

## environment

**cross-platform dotfiles** targeting Arch, Ubuntu, Fedora, macOS, WSL2

**typical setup:**
- package managers: pnpm (Node.js), pip/pyenv (Python), cargo (Rust)
- shell: Bash and Zsh (parallel configs maintained via GNU Stow dotfiles)
- editors: Neovim, VSCode Insiders, Cursor, PyCharm (varies by system)
- terminals: Ghostty, Kitty, Alacritty, Wezterm (varies by system)

**directory structure:**
```
~/
├── dotfiles/           # GNU Stow-managed dotfiles (Git repo)
│   ├── home/          # Stow package: shell, git, tmux, terminal configs
│   ├── claude/        # Stow package: Claude Code global config
│   └── lib/common.sh  # Shared installer functions
├── code/              # Development projects
│   ├── personal/      # Personal projects
│   ├── university/    # University coursework
│   ├── compsoc/       # Computer Society projects
│   └── templates/     # Project templates
├── obsidian/          # Knowledge vault (Git + LFS)
├── projects/          # Active development workspace
└── Scripts/           # Custom automation scripts
```

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

## common commands

### dotfiles management
```bash
cd ~/dotfiles

# preview what would be symlinked
./setup.sh --dry-run

# deploy all dotfiles with backup
./setup.sh

# deploy single package
stow home     # shell configs, git, tmux, etc.
stow claude   # Claude Code global config

# install dependencies (OS-detected)
./install-deps.sh

# full interactive setup
./install.sh

# switch to zsh
./switch-to-zsh.sh
```

### shell aliases (available in bash/zsh)
```bash
# file operations
ll, la, l       # eza-based listings with icons/git
mkcd <dir>      # mkdir + cd
backup <file>   # creates timestamped .bak copy
extract <file>  # multi-format archive extraction

# git (70+ aliases, key ones)
ga              # git add
gco             # git checkout
gd              # git diff
gp              # git pull --rebase
gb              # git branch
gc              # git commit
gst             # git status

# docker shortcuts
dps             # docker ps
dexec           # docker exec -it
dlogs           # docker logs -f
dprune          # full system prune

# system (Arch-specific)
cleanup         # 7-step system cleanup (pacman, AUR, cache, logs)
```

## dotfiles architecture

**stow-based system**: each top-level directory in ~/dotfiles/ is a standalone package that mirrors $HOME structure. run `stow <package>` to deploy.

**installer scripts** share `lib/common.sh` for:
- color output (`info`, `success`, `warn`, `error`)
- os detection (`detect_os`, `is_wsl`)
- error handling (all scripts use `set -e`)

**shell config split**:
- `.bashrc`/`.zshrc` - main config, tool integrations (NVM, Cargo, Zoxide, FZF, TheFuck, Starship)
- `_aliases` - command shortcuts (eza, docker, git, etc.)
- `_functions` - helper functions (mkcd, backup, extract, cleanup)
- changes to one shell should have equivalent in the other (maintain parity)

## obsidian vault structure

located at `~/obsidian/` (Git-tracked with LFS for media):

- **module directories**: kebab-case (e.g. `ct213-computer-systems-and-organisation`)
- **note naming**: either "N. Topic.md" or "Lecture N.md" (check module convention first)
- **tagging**: lowercase, singular, max 2 nesting levels
- **dataview queries**: used for content aggregation
- **custom agents**: lecture-atomizer, topic-extractor, link-weaver, exam-index-generator

## important patterns

**stow-aware**:
- new config files go inside appropriate package directory mirroring $HOME structure
- never place files directly in `~` when managing dotfiles
- run `stow <package>` from ~/dotfiles/ to deploy changes

**cross-platform**:
- dotfiles target: Arch (primary), Ubuntu, Fedora, macOS, WSL2
- scripts auto-detect OS and adjust behavior
- WSL2 detection: skips terminal emulator configs (use Windows Terminal)

**error handling**:
- all installer scripts use `set -e` (fail-fast)
- use `lib/common.sh` helpers for colored output
- graceful OS detection with fallbacks
