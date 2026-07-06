# Home Package - Shell Configuration & Utilities

This package contains comprehensive shell configurations for both **bash** and **zsh**, providing a unified experience across both shells. All configurations are designed for Arch Linux with support for Ubuntu, Fedora, macOS, and WSL2.

## Overview

The `home/` package provides:

- **Unified bash and zsh configurations** with feature parity
- **102+ git aliases** for efficient version control workflows
- **Comprehensive utility functions** for daily development tasks
- **Integrated tool support**: NVM, Cargo, FZF, Zoxide, Starship, TheFuck, Pyenv
- **Catppuccin Mocha theming** via Starship prompt
- **Gaming/Wayland optimizations** for Hyprland users
- **SSH agent management** with automatic startup

## Quick Start

### Deploy with Stow

```bash
cd ~/dotfiles
stow home              # Deploy home package
source ~/.bashrc       # Reload bash, or
source ~/.zshrc        # Reload zsh
```

### Switch Default Shell

```bash
# Switch to zsh (Oh My Zsh)
./switch-to-zsh.sh

# Or manually
chsh -s /usr/bin/zsh
```

## Configuration Files

| File                    | Purpose                            |
| ----------------------- | ---------------------------------- |
| `.bashrc`               | Bash main configuration            |
| `.bash_aliases`         | Bash aliases (102 git + utilities) |
| `.bash_functions`       | Bash utility functions             |
| `.bash_profile`         | Bash login shell config            |
| `.zshrc`                | Zsh main config (uses Oh My Zsh)   |
| `.zsh_aliases`          | Zsh aliases (mirrored from bash)   |
| `.zsh_functions`        | Zsh utility functions              |
| `.config/starship.toml` | Starship prompt configuration      |
| `.config/nvim`          | LazyVim-based Neovim configuration |
| `.tmux.conf`            | Tmux configuration                 |
| `.gitconfig`            | Git configuration                  |

## Key Features

### Bash vs Zsh

Both shells are fully configured with **feature parity**:

- **Bash** (`~/.bashrc`)
    - Traditional shell scripting language
    - Direct git alias support (all 102 aliases)
    - Custom welcome bar with CPU/RAM usage
    - SSH agent auto-management
    - Good for scripts and portability

- **Zsh** (`~/.zshrc`)
    - Modern shell with Oh My Zsh framework
    - Better completion system and theming
    - Time-aware welcome greeting
    - Enhanced key bindings for navigation
    - Recommended for interactive use

### Shell Aliases

All 102 aliases are organized by category:

#### Navigation

```bash
..        # cd ..
...       # cd ../..
....      # cd ../../..
-         # cd -
```

#### File Listing

```bash
ls        # Use eza if available, else ls with colors
ll        # Long listing with hidden files
la        # All files (hidden included)
l         # Short listing
lt        # Files sorted by modification time
tree      # Tree view with colors
```

#### Utilities

```bash
c         # clear
h         # history
myip      # Show public IP
localip   # Show local IP
df        # Disk usage (human-readable)
du        # Directory size (human-readable)
ports     # Show listening ports
update    # sudo pacman -Syu
```

#### Safe Operations

```bash
cp        # cp -i (interactive)
mv        # mv -i (interactive)
rm        # rm -i (interactive - CAREFUL!)
```

#### Docker

```bash
dps       # docker ps
dpsa      # docker ps -a
di        # docker images
dexec     # docker exec -it
dlogs     # docker logs -f
dstop     # docker stop
drm       # docker rm
dprune    # docker system prune -af
```

#### Git (102 aliases)

```bash
# Basic operations
g         # git
ga        # git add
gaa       # git add --all
gap       # git add -p (interactive)
gb        # git branch
gbr       # git branch -r (remote)
gba       # git branch -a (all)
gc        # git commit -m <message>
gca       # git commit -am (add + commit)
gco       # git checkout
gcb       # git checkout -b (create branch)
gcp       # git cherry-pick

# Diff & Status
gd        # git diff
gds       # git diff --staged
gs        # git status -sb (short with branch)
gst       # git status (full)
gsh       # git show

# Log & History
gl        # git log --oneline --graph
gll       # git log (detailed, pretty format)

# Push/Pull
gp        # git push
gpf       # git push --force-with-lease (safer)
gpo       # git push origin
gpu       # git push --set-upstream origin

# Rebase & Reset
gr        # git rebase
gri       # git rebase -i (interactive)
grs       # git reset
grh       # git reset --hard

# Stash
gss       # git stash
gsp       # git stash pop
gsa       # git stash apply
gsl       # git stash list

# Fetch & Tags
gf        # git fetch
gfa       # git fetch --all --prune
gt        # git tag
gsu       # git submodule update --init --recursive
```

#### Neovim/Editor

```bash
v         # nvim
vi        # nvim
vim       # nvim
e         # Use configured $EDITOR
vconf     # Edit nvim config
zshrc     # Edit ~/.zshrc
zalias    # Edit ~/.zsh_aliases
bashrc    # Edit ~/.bashrc
balias    # Edit ~/.bash_aliases
tconf     # Edit tmux config
```

The Neovim config is a slim LazyVim setup using Catppuccin Mocha, neo-tree, transparent backgrounds, and optional Molten/Jupyter support. See `.config/nvim/README.md` for editor-specific notes.

#### Tmux

```bash
t         # tmux
ta        # tmux attach
tat       # tmux attach -t <session>
tns       # tmux new-session -s <name>
tls       # tmux list-sessions
tks       # tmux kill-session -t <session>
```

#### Lazygit

```bash
lg        # lazygit (TUI git client)
```

#### Shell

```bash
reload    # source ~/.bashrc (bash) or ~/.zshrc (zsh)
```

### Utility Functions

#### File Operations

```bash
mkcd <dir>          # mkdir + cd in one command
backup <file>       # Create timestamped .bak copy
f <pattern>         # Find files by name
ftext <pattern>     # Search text in files
extract <archive>   # Extract any archive format (tar, zip, 7z, etc.)
```

#### SSH

```bash
sssh <host>         # SSH with completion (see config for details)
```

#### System

```bash
cleanup             # 7-step Arch cleanup:
                    # 1. pacman cache cleanup
                    # 2. AUR package cleanup
                    # 3. Systemd journal cleanup
                    # 4. Temp files cleanup
                    # 5. Package removal
                    # 6. Broken symlinks cleanup
                    # 7. Database cleanup
```

#### Gaming Helpers

- `gcheck` - show installed gaming packages and the Vulkan driver summary
- `gmodes` - print suggested Steam and Heroic launch modes
- `pplus` - open ProtonPlus to manage GE-Proton and Wine-GE

### Tool Integration

The shell automatically initializes these tools (if installed):

#### Node Version Manager (NVM)

```bash
nvm list              # List installed Node versions
nvm install 20.0.0    # Install specific version
nvm use 20.0.0        # Switch version
```

#### Rust/Cargo

```bash
cargo build          # Build Rust project
cargo run            # Run Rust project
```

#### Python (Pyenv)

```bash
pyenv versions       # List Python versions
pyenv local 3.12     # Use Python 3.12 in current dir
```

#### Zoxide (Smarter cd)

```bash
z <pattern>          # Jump to frequently visited directory
zi                   # Interactive selection (alias: cdi)
```

#### FZF (Fuzzy Finder)

```bash
Ctrl+T               # Open file picker
Ctrl+R               # Fuzzy history search
```

#### TheFuck (Command Corrector)

```bash
<mistyped command>
fuck                 # Correct last command
f <query>            # Search for correction
```

#### Starship Prompt

Automatic prompt initialization with:

- **Color scheme**: Catppuccin Mocha
- **Git integration**: Branch, status icons
- **Language detection**: Shows runtime versions when relevant
- **Execution time**: Shows slow commands
- **Exit status**: Red for failures, green for success

### Theming

#### Color Scheme: Catppuccin Mocha

All tools are themed with **Catppuccin Mocha** for consistency:

- **Base**: `#1e1e2e` (dark background)
- **Crust**: `#11111b` (darker background)
- **Mantle**: `#181825` (alternative background)
- **Text**: `#cdd6f4` (light text)
- **Accent**: `#a6adc8` (secondary text)
- **Primary**: `#89b4fa` (blue highlight)

### Starship Configuration

Located at `~/.config/starship.toml`:

- Command execution time display
- Git branch and status symbols
- Language version detection
- Working directory truncation
- Custom character for prompt
- Catppuccin Mocha color scheme

## Development Environment

### Python

- **Pyenv** integration for version management
- **Pip** support with auto-completion
- Python 3.13+ recommended

### Node.js

- System Node.js from pacman
- NPM/PNPM package managers
- PNPM_HOME globals in `~/.local/share/pnpm`

### Rust

- **Cargo** auto-initialized
- Full Rust toolchain support

### Docker

- Pre-configured aliases for common operations
- 8 docker aliases for faster workflows

### Java

- OpenJDK 25 support
- Configured for JVM development

## Gaming & Wayland (Hyprland)

For users on Hyprland (Wayland desktop):

### Proton/Steam Configuration

```bash
export PROTON_LOG=0                      # Set to 1 for debug
export WINE_CPU_TOPOLOGY=4:2             # Optimize for 4-core systems
export STAGING_SHARED_MEMORY=1           # Enable shared memory
export SDL_VIDEODRIVER=wayland           # Prefer Wayland for SDL2
```

### PyCharm on Hyprland

- Handles QT_QPA_PLATFORM automatically from Hyprland session
- If crashes occur: `QT_QPA_PLATFORM=xcb pycharm`

## History Configuration

Both shells maintain comprehensive history:

- **HISTSIZE**: 50,000 commands in memory (bash/zsh)
- **HISTFILESIZE**: 100,000 commands on disk (bash)
- **SAVEHIST**: 100,000 commands on disk (zsh)
- **HISTFORMAT**: Includes timestamps: `%F %T`
- **Deduplication**: Automatic removal of duplicate entries
- **Synchronization**: Bash syncs history across sessions (zsh shares)

## SSH Agent

Automatic SSH agent management:

- Starts agent on shell initialization
- Persistent across sessions
- Credentials stored in `~/.ssh/agent-environment`
- Automatic restart if crashed

## Completion Systems

### Bash

- System bash completion framework
- Git command completion via `.bash_aliases`
- Custom SSH host completion

### Zsh

- Oh My Zsh completion plugins
- Fuzzy matching and case-insensitive completion
- Custom styling with colors

## Extending Configuration

### Add Custom Aliases

Create shell-specific files for local overrides:

```bash
# Bash
echo "alias myalias='my command'" >> ~/.bash_aliases.local

# Zsh
echo "alias myalias='my command'" >> ~/.zsh_aliases.local
```

### Add Custom Functions

```bash
# Bash
cat >> ~/.bash_functions.local << 'EOF'
myfunc() {
    echo "Do something"
}
EOF

# Zsh
cat >> ~/.zsh_functions.local << 'EOF'
myfunc() {
    echo "Do something"
}
EOF
```

### Local Machine Config

Create `~/.bashrc.local` or `~/.zshrc.local` for machine-specific settings:

```bash
# ~/.bashrc.local (sourced at end of .bashrc)
export MY_VAR="value"
alias myalias="command"
```

## Troubleshooting

### Aliases not working

- Ensure `~/.bash_aliases` or `~/.zsh_aliases` is sourced
- Check file permissions: `ls -la ~/.bash_aliases`
- Reload shell: `reload` alias or `source ~/.bashrc`

### Functions not working

- Similar to aliases, check sourcing
- Ensure `.bash_functions` or `.zsh_functions` exists
- Reload shell and test: `mkcd test_dir`

### Git aliases conflicting

- Zsh's Oh My Zsh git plugin provides common aliases
- Our custom aliases override or complement omz (documented in `.zsh_aliases`)
- Check `git <command> --help` if unsure

### Starship prompt not showing

```bash
# Install Starship
cargo install starship

# Or via package manager (Arch)
sudo pacman -S starship
```

### FZF history search not working

```bash
# Install FZF
sudo pacman -S fzf

# Or from source
git clone https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
```

## Performance Notes

- **Bash startup**: ~200ms (includes all completions)
- **Zsh startup**: ~300ms (includes Oh My Zsh framework)
- **Tool integration**: All tools are conditionally loaded (only if installed)
- **FZF**: Configured to use `fd` if available for 10x faster fuzzy finding

## References & Attribution

Configuration built on best practices from:

- **Oh My Bash**: Common bash aliases and structure
- **Oh My Zsh**: Framework and plugins
- **Starship**: Prompt customization and appearance
- **Community configs**: Various open-source dotfiles projects

Special thanks to the Arch Linux, Catppuccin, and Starship communities for inspiration and tools.

## Platform Support

Tested and working on:

- ✅ Arch Linux (primary development environment)
- ✅ Ubuntu 20.04+
- ✅ Fedora 35+
- ✅ macOS 12+
- ✅ WSL2 (Windows Subsystem for Linux)

## Next Steps

For more detailed information on shell-specific features and comparison, see [SHELL_GUIDE.md](../docs/SHELL_GUIDE.md).

For full dotfiles deployment and setup instructions, see the root [README.md](../README.md).
