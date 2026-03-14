# Installation & Dependency Management Guide

Complete guide to installing and managing dependencies for the dotfiles repository. This document explains what each package does, how the installation process works, and how to troubleshoot issues.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Installation Process](#installation-process)
3. [Package Categories](#package-categories)
4. [Detailed Package Reference](#detailed-package-reference)
5. [Platform-Specific Notes](#platform-specific-notes)
6. [Troubleshooting](#troubleshooting)
7. [Post-Installation Setup](#post-installation-setup)

## Quick Start

```bash
# Run the installation script
./install-deps.sh

# Or run full setup (dotfiles + dependencies)
./install.sh
```

The installer will:
1. Detect your OS and package manager
2. Show system information
3. Ask which shell you want (Bash or Zsh)
4. Ask which optional tools to install
5. Ask which development tools to install
6. Ask whether to install Hyprland/Waybar (desktop environment)
7. Display all packages before installing
8. Install packages with clear progress
9. Run post-installation setup (TPM, Oh My Zsh)
10. Show a summary with next steps

A log file is automatically created at `~/.dotfiles-install-YYYYMMDD_HHMMSS.log` for reference.

## Installation Process

### Step 1: System Detection

The installer automatically detects:
- **Operating System**: Arch, Ubuntu/Debian, Fedora, macOS, WSL2
- **Package Manager**: pacman, yay, paru, apt, dnf, brew (auto-selected based on OS)
- **Environment**: Detects WSL2 and macOS to skip desktop packages

```
Example output:
  Operating System: Arch Linux
  Base OS: arch
  Package Manager: paru (AUR support enabled)
```

### Step 2: Interactive Choices

The installer presents a series of interactive prompts:

#### Shell Selection
Choose between Bash or Zsh:
- **Bash** (POSIX-compatible, lightweight, default)
- **Zsh** (modern features, Oh My Zsh framework)

If you choose Zsh, you'll be offered to install Oh My Zsh (a framework with 40+ plugins and themes).

#### Optional Tools
Decide which convenience tools to install:
- **lazygit** - TUI for git commands
- **dooit** - Simple todo list manager
- **pomodoro-tui** - Pomodoro timer
- **thefuck** - Automatic command corrector

These add convenience but aren't required. They can be installed anytime with your package manager.

#### Development Tools
Decide which development environments to install:
- **nvm** - Node.js version manager
- **pyenv** - Python version manager
- **rustup** - Rust toolchain manager

Install only what you need. These take up significant disk space.

#### Desktop Environment (Arch/Linux only)
If not on WSL2 or macOS, you'll be offered to install:
- **Hyprland** - Wayland window manager
- **Waybar** - Status bar
- **Swaync** - Notification center

Skip on non-Hyprland systems.

### Step 3: Package Review

Before installation begins, you'll see a **complete list of all packages** that will be installed. This uses `less` for interactive viewing, so you can:
- Scroll up/down
- Search with `/`
- Quit with `q`

No packages are installed until you've confirmed this list.

### Step 4: Installation

The installer separates packages into two categories:

**Critical packages** (must succeed):
- Must install for shell configuration to work
- Examples: zsh, bash, git, tmux, fzf
- If a critical package fails, installation stops immediately with an error

**Optional packages** (can fail gracefully):
- Nice to have, but not required
- Examples: lazygit, pomodoro-tui
- If optional packages fail, installation continues with a warning

### Step 5: Post-Installation Setup

After package installation, the script:
1. **Installs TPM** (Tmux Plugin Manager) if tmux was installed
2. **Installs Oh My Zsh** if you selected it (runs unattended)
3. **Shows a summary** with results and next steps

## Package Categories

### Critical Shell Packages (Must Install)

These packages are required for the shell configuration to function properly:

| Package | Purpose | Aliases Dependent |
|---------|---------|-------------------|
| **bash** | POSIX-compatible shell (default if not choosing zsh) | All bash aliases |
| **zsh** | Modern shell with advanced features (optional) | All zsh aliases |
| **git** | Version control system | 70+ git aliases |
| **tmux** | Terminal multiplexer | tmux-related aliases |
| **fzf** | Fuzzy finder for file/history search | `Ctrl+R`, `Ctrl+T`, search functions |
| **ripgrep** | Fast text search | `ftext()` function |
| **fd** | Fast file finder | `f()` function for finding files |
| **bat** | Cat replacement with syntax highlighting | `cat` alias |
| **eza** | Modern ls replacement with colors | `ls, ll, la, l, lt, tree` aliases |
| **zoxide** | Smart directory jumper | `cdi` alias |
| **starship** | Modern prompt | Shell prompt theming |

**Why critical?** These tools are directly used by shell aliases and functions. Without them, many shortcuts won't work.

### Optional Shell Tools

These packages add extra convenience but aren't required:

| Package | Purpose | Usage |
|---------|---------|-------|
| **lazygit** | TUI for git operations | `lg` alias |
| **dooit** | Todo list manager | `todo` alias |
| **pomodoro-tui** | Pomodoro timer | `pomodoro` alias |
| **thefuck** | Auto-correct shell commands | `fuck()` function |

**Installation**: Choose during interactive prompt, or install anytime:
```bash
# Arch
sudo pacman -S lazygit

# Ubuntu/Debian
sudo apt install lazygit

# macOS
brew install lazygit
```

### Development Tools

Version managers for programming languages:

| Package | Purpose | Installs | Size |
|---------|---------|----------|------|
| **nvm** | Node.js version manager | Node.js, npm, npx | ~200MB per version |
| **pyenv** | Python version manager | Python interpreters | ~500MB per version |
| **rustup** | Rust toolchain manager | Rust compiler, cargo | ~1GB |

**When to install**:
- **nvm**: If you do Node.js/JavaScript development
- **pyenv**: If you do Python development
- **rustup**: If you do Rust development

**After installation**, manage versions:
```bash
# Node.js
nvm list              # Show installed versions
nvm install 22.0.0    # Install specific version
nvm use 22.0.0        # Switch version

# Python
pyenv versions        # Show installed versions
pyenv install 3.13.0  # Install specific version
pyenv local 3.13.0    # Set version for current directory

# Rust
rustup update         # Update toolchain
rustup toolchain list # Show installed toolchains
```

### Desktop Environment Packages (Arch/Linux only)

Only offered on Arch/Fedora/Ubuntu (skipped on WSL2 and macOS):

| Package | Purpose | Dependencies |
|---------|---------|---------------|
| **hyprland** | Wayland window manager | Core display server |
| **waybar** | Status bar for Hyprland | Displays time, battery, etc. |
| **swaync** | Notification center | Notification daemon |

**Skip if**: You use a different desktop environment (KDE, GNOME, etc.)

### System Utilities

Standard system tools:

| Package | Purpose |
|---------|---------|
| **curl** | HTTP client for downloads |
| **wget** | Alternative HTTP/FTP client |
| **rsync** | Fast file synchronization |
| **jq** | JSON processor |
| **tree** | Directory tree visualization |

## Detailed Package Reference

### Aliases & Their Dependencies

This table shows which packages each alias depends on. If a dependency is missing, the alias won't work:

#### File/Directory Operations
```bash
ll, la, l, lt, tree    → eza
f <pattern>            → fd
cat <file>             → bat
```

#### Git Commands (70+ aliases)
```bash
ga, gc, gd, gb, gst    → git
lg                      → lazygit (optional)
```

#### Development
```bash
nvm (Node.js)          → Installs during dev tools setup
pyenv (Python)         → Installs during dev tools setup
rustup (Rust)          → Installs during dev tools setup
```

#### Utility Functions
```bash
mkcd <dir>             → bash/zsh built-in
backup <file>          → bash/zsh built-in
extract <file>         → bash/zsh built-in, external tools (unzip, tar, etc.)
f <pattern>            → fd
ftext <pattern>        → ripgrep
cleanup                → pacman/apt (package manager)
cdi                    → zoxide
```

### Critical Path for Aliases

For shell aliases to work at all:

1. **Shell itself** (bash or zsh)
2. **Git** (for 70+ git aliases)
3. **Eza** (for ls-style aliases)
4. **Bat** (for cat alias)
5. **Fd** (for file finding)
6. **Ripgrep** (for text searching)
7. **Starship** (for prompt customization)

Without these, approximately 90% of aliases won't function.

## Platform-Specific Notes

### Arch Linux

**Recommended package manager**: `paru` (AUR support) > `yay` (AUR support) > `pacman` (official repos only)

The installer will auto-detect and prefer AUR-capable managers for better package availability.

**Package names** are as expected (e.g., `fd`, `bat`, `ripgrep`, `eza`).

### Ubuntu / Debian

**Package manager**: `apt`

**Important notes**:
- `bat` is packaged as `batcat` (with symlink workaround in newer versions)
- `fd` is packaged as `fd-find`
- `fzf` may need manual installation or sourcing from ~/.fzf

**Installing from source** (if available packages are outdated):
```bash
# Example: Install ripgrep from source
git clone https://github.com/BurntSushi/ripgrep
cd ripgrep
cargo build --release
sudo cp target/release/rg /usr/local/bin/
```

### Fedora

**Package manager**: `dnf`

Package names generally match official repos. Uses RPM packages.

### macOS

**Package manager**: `brew`

**Important notes**:
- Desktop packages (Hyprland, Waybar, Swaync) are automatically skipped
- Starship theme is still available
- Shell configuration works identically to Linux

### WSL2 (Windows Subsystem for Linux)

**Important notes**:
- Detected automatically; desktop packages are skipped
- Use Windows Terminal instead of installing terminal emulators
- All command-line tools work identically to native Linux
- Git configuration can be shared with Windows git installations

## Troubleshooting

### Alias Not Working

**Symptom**: You run an alias and get `command not found`

**Diagnosis**:
```bash
# Check if alias exists
alias ll

# Check if underlying tool is installed
command -v eza
which eza

# Check if alias file was sourced
grep "^alias ll=" ~/.bashrc

# List all loaded aliases
alias | grep "ll"
```

**Solution**:
1. Verify the tool is installed: `pacman -Q eza` (Arch) or `dpkg -l | grep eza` (Ubuntu)
2. Reload shell: `source ~/.bashrc` or `exec bash`
3. If still missing, install the tool: `sudo pacman -S eza`

### Critical Package Installation Failed

**Symptom**: Installation stopped with error on a critical package

**Example**:
```
Error: Failed to install git
[packages output here]
Fatal error: Critical package failed
Aborting installation
```

**Solution**:
1. Check network connectivity: `ping 8.8.8.8`
2. Update package manager: `sudo pacman -Sy` or `sudo apt update`
3. Check disk space: `df -h /`
4. Install package manually:
   ```bash
   # Arch
   sudo pacman -S git
   
   # Ubuntu
   sudo apt install git
   
   # macOS
   brew install git
   ```
5. Run installer again: `./install-deps.sh`

### Optional Package Failed (Installation Continued)

**Symptom**: Saw a warning but installation continued

**Example**:
```
Warning: Optional package 'lazygit' failed to install
Continuing installation...
[installation proceeds]
```

**Solution**: This is not an error. Optional packages can fail without breaking anything. Install manually later if needed:
```bash
sudo pacman -S lazygit      # Arch
sudo apt install lazygit    # Ubuntu
brew install lazygit        # macOS
```

### Shell Not Switching to Zsh

**Symptom**: Installed Zsh but still using Bash

**Solution**:
```bash
# 1. Verify Zsh was installed
zsh --version

# 2. Check what your current shell is
echo $SHELL

# 3. Change default shell
chsh -s /usr/bin/zsh

# 4. Log out and back in, or use:
exec zsh
```

### FZF Not Working (Ctrl+R, Ctrl+T)

**Symptom**: History search and file picker don't work

**Diagnosis**:
```bash
# Check if fzf is installed
command -v fzf

# Check if fzf keybindings are loaded
echo $FZF_COMPLETION_OPTS

# Try manually loading
source /usr/share/fzf/completion.bash  # Arch
source /usr/share/fzf/shell/key-bindings.bash
```

**Solution**:
1. Install fzf: `sudo pacman -S fzf`
2. Reload shell: `source ~/.bashrc`
3. Test: Press `Ctrl+R` to search history

### Oh My Zsh Not Loading

**Symptom**: Zsh works but Oh My Zsh theme/plugins not available

**Solution**:
```bash
# Check Oh My Zsh installation
test -d ~/.oh-my-zsh && echo "installed" || echo "not installed"

# Reinstall manually
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Reload shell
exec zsh
```

### Git Aliases Not Working (Especially Zsh)

**Symptom**: Git aliases like `ga`, `gc`, `gd` don't work

**Diagnosis**:
```bash
# Check if git aliases file exists
test -f ~/.zsh_aliases && echo "found" || echo "missing"

# Check what's defined
alias | grep "^ga="

# Check bash version of the same
grep "alias ga=" ~/.zsh_aliases
```

**Solution**:
```bash
# Reload shell configuration
source ~/.zshrc

# Or restart shell
exec zsh
```

### Tmux Not Finding Plugins (TPM)

**Symptom**: Tmux starts but plugins (copycat, resurrect, etc.) not available

**Solution**:
```bash
# TPM should be installed at ~/.tmux/plugins/tpm
test -d ~/.tmux/plugins/tpm && echo "found" || echo "missing"

# Install manually if missing
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Load plugins in tmux
tmux source-file ~/.config/tmux/chadmux.conf

# Or press Ctrl+B (prefix) then I (capital i) to auto-install
```

### Package Manager Not Found

**Symptom**: Installer can't detect your package manager

**Example**:
```
Error: Could not detect package manager
Supported: pacman, apt, dnf, brew
```

**Solution**:
1. Check which package managers are installed:
   ```bash
   which pacman apt dnf brew
   ```
2. For Arch-based: install `pacman` (should be default)
3. For Ubuntu: `apt` should be available
4. For Fedora: `dnf` should be available
5. For macOS: install Homebrew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

### Missing Package for Your Distro

**Symptom**: Installer found a package but your distro uses different name

**Example**:
```
Ubuntu has 'fd-find' but script expects 'fd'
```

**Solution**: These are handled automatically by the package name mapping system in `lib/package-lists.sh`. If you find a missing mapping:
1. Report it: Submit an issue to the repository
2. Workaround: Install manually with the correct package name
3. Create symlink:
   ```bash
   # Ubuntu example
   sudo ln -s /usr/bin/fd-find /usr/local/bin/fd
   ```

### Slow Installation

**Symptom**: Installation is taking too long

**Solution**:
```bash
# Check what's happening
# 1. Look at the log file
tail -f ~/.dotfiles-install-*.log

# 2. Check package manager status
ps aux | grep pacman  # or apt, dnf, brew

# 3. Check network
ping -c 3 8.8.8.8
```

Common reasons:
- Network is slow or unstable
- Package manager is updating (first run)
- Building from source (some packages)
- Large downloads (Rust, Python versions)

## Post-Installation Setup

### Verify Installation

After installation completes, verify everything is working:

```bash
# 1. Check core tools
git --version
fzf --version
bat --version
eza --version
zoxide --version
ripgrep --version

# 2. Test aliases
ll              # Should show directory with colors and icons
la              # Should show all files
l               # Should show directory

# 3. Test shell
echo $SHELL     # Should show /bin/bash or /bin/zsh
bash --version
zsh --version

# 4. Test git
git config user.name
git config user.email

# 5. Test functions
mkcd test_dir   # Should create and cd into directory
backup ~/.bashrc # Should create ~/.bashrc.bak
```

### Update Aliases

If you installed tools after running the installer, reload your shell configuration:

```bash
# Bash
source ~/.bashrc

# Zsh
source ~/.zshrc

# Or restart terminal
exec bash
exec zsh
```

### Switch Between Shells

If you installed Zsh but want to switch back to Bash (or vice versa):

```bash
# Check available shells
cat /etc/shells

# Change default shell
chsh -s /usr/bin/bash    # Switch to Bash
chsh -s /usr/bin/zsh     # Switch to Zsh

# Verify change
echo $SHELL

# Log out and back in, or use:
exec bash
exec zsh
```

### Customization

After installation, customize your shell:

1. **Machine-specific config**: Create `~/.bashrc.local` or `~/.zshrc.local`
2. **Custom aliases**: Create `~/.bash_aliases.local` or `~/.zsh_aliases.local`
3. **Custom functions**: Add to `.bash_functions.local` or `.zsh_functions.local`

See `home/SHELL_GUIDE.md` for detailed customization instructions.

### Development Environment Setup

If you installed development tools:

```bash
# Node.js (nvm)
nvm install 22.0.0
nvm use 22.0.0
npm --version

# Python (pyenv)
pyenv install 3.13.0
pyenv local 3.13.0
python --version

# Rust (rustup)
rustup update
cargo --version
```

### Further Reading

For detailed information:
- **Shell configuration**: See `home/README.md` and `home/SHELL_GUIDE.md`
- **Aliases reference**: Check `home/.bash_aliases` (or `.zsh_aliases`)
- **Functions reference**: Check `home/.bash_functions` (or `.zsh_functions`)
- **Git setup**: See `home/.gitconfig` and `home/.config/git/`

### Getting Help

1. **Check the log file**: `~/.dotfiles-install-YYYYMMDD_HHMMSS.log`
2. **Read troubleshooting section** above
3. **Check shell guide**: `home/SHELL_GUIDE.md` in the repository
4. **Report issues**: Open an issue on the repository

---

**Last updated**: 2026-03-14  
**Repository**: https://github.com/yourusername/dotfiles  
**Documentation**: See `README.md` for full project overview
