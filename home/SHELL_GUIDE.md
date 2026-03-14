# Shell Configuration Guide

Comprehensive guide to bash and zsh configurations, including detailed feature comparison, architecture, and advanced usage.

## Table of Contents

1. [Configuration Architecture](#configuration-architecture)
2. [Bash vs Zsh Comparison](#bash-vs-zsh-comparison)
3. [Shell Initialization](#shell-initialization)
4. [Feature Parity](#feature-parity)
5. [Advanced Configuration](#advanced-configuration)
6. [Troubleshooting](#troubleshooting)

## Configuration Architecture

### File Organization

Both shells follow a modular architecture:

```
home/
├── .bashrc                # Main bash configuration
├── .bash_aliases          # Git + utility aliases (140 lines)
├── .bash_functions        # Utility functions + welcome bar (182 lines)
├── .bash_profile          # Login shell configuration
├── .zshrc                 # Main zsh configuration (uses Oh My Zsh)
├── .zsh_aliases           # Git + utility aliases (mirrored from bash)
├── .zsh_functions         # Utility functions (zsh-specific)
├── .config/
│   ├── starship.toml      # Prompt configuration
│   ├── tmux/
│   │   └── chadmux.conf   # Tmux configuration
│   └── ...                # Other tool configs
├── .gitconfig             # Git configuration
├── README.md              # Main documentation
└── SHELL_GUIDE.md         # This file
```

### Sourcing Order

Both shells follow a consistent sourcing pattern:

```bash
# 1. Environment variables
# 2. History configuration
# 3. Shell options
# 4. Completions
# 5. Tool integrations (NVM, Cargo, Zoxide, FZF, etc.)
# 6. SSH agent
# 7. Aliases
# 8. Functions
# 9. Welcome message
# 10. Local overrides (.bashrc.local / .zshrc.local)
```

## Bash vs Zsh Comparison

### Feature Matrix

| Feature | Bash | Zsh | Notes |
|---------|------|-----|-------|
| **Language** | POSIX-compatible shell | Extended shell with advanced features | Zsh superset of bash |
| **Oh My Zsh** | N/A | ✅ Full integration | Framework for themes/plugins |
| **Framework** | Manual configuration | ✅ Built-in plugins | 40+ plugins via Oh My Zsh |
| **Completion** | Basic (COMPREPLY) | ✅ Advanced (zstyle) | Zsh completion much more powerful |
| **Auto-CD** | Disabled | ✅ Enabled (AUTO_CD) | Type directory name to cd |
| **Glob patterns** | Basic | ✅ Extended | Better pattern matching |
| **Theming** | Via Starship | ✅ Via Starship + Oh My Zsh | Both use Starship (recommended) |
| **Aliases** | 140+ directly | 140+ (some via Oh My Zsh) | Different delegation strategy |
| **Startup time** | ~200ms | ~300ms | Minimal difference |
| **Scripting** | ✅ Better | ✅ Good | Bash better for POSIX portability |
| **Interactive use** | Good | ✅ Better | Zsh superior for daily use |

### Bash Strengths

1. **POSIX Compliance**
   - Maximum portability across systems
   - Better for shell scripts
   - Default on many Unix systems

2. **Direct Alias Access**
   - All 140+ aliases directly available
   - No reliance on external plugins
   - Simpler alias management

3. **Lower startup overhead**
   - No framework initialization
   - Pure configuration files
   - Faster on slower systems

4. **Welcome Bar**
   - Custom CPU/RAM usage display
   - Color-coded progress bars
   - System resource awareness on login

### Zsh Strengths

1. **Oh My Zsh Framework**
   - 40+ community plugins
   - Powerful git plugin integration
   - Theme support (we use Starship)
   - Active community development

2. **Superior Completion System**
   - Context-aware suggestions
   - Fuzzy matching support
   - Color-coded output
   - Faster completion generation

3. **Auto-CD**
   - Type directory name, automatically cd
   - Saves keystrokes on frequent navigation
   - Configurable via `AUTO_CD` option

4. **Enhanced Globbing**
   - Extended pattern matching: `setopt EXTENDED_GLOB`
   - More powerful filename patterns
   - Recursive globbing with `**`

5. **Time-Aware Welcome**
   - "Good morning/afternoon/evening"
   - Context-sensitive greeting
   - More personalized experience

6. **Better Keyboard Navigation**
   - Configurable key bindings
   - History search with arrow keys
   - Modal editing support (via zle)

### Equivalent Features

Both shells provide:
- 140+ aliases organized by category
- Comprehensive utility functions
- Tool integration (NVM, Cargo, FZF, Zoxide, etc.)
- SSH agent management
- Starship prompt
- Git configuration
- Tmux integration
- Full history with timestamps
- Interactive corrections (disabled, too aggressive)
- Safe operations (rm -i, cp -i, mv -i)

## Shell Initialization

### Bash Initialization Process

```
1. .bash_profile (login shell)
   └── .bashrc

.bashrc order:
  ├── Interactive check [[ $- != *i* ]]
  ├── Environment variables
  ├── History configuration
  ├── Shell options (shopt -s)
  ├── Bash completions
  ├── Color support
  ├── Tool integrations (NVM, Cargo, Zoxide, FZF, TheFuck, Starship)
  ├── SSH agent
  ├── source ~/.bash_aliases
  ├── source ~/.bash_functions
  ├── _welcome_bar (CPU/RAM display)
  ├── source ~/.bashrc.local (if exists)
  ├── Pyenv initialization
  └── Hyprland/Wayland environment
```

### Zsh Initialization Process

```
1. .zshrc (all interactive shells)

.zshrc order:
  ├── Oh My Zsh initialization
  │   ├── Load Oh My Zsh framework
  │   ├── Load plugins (git, docker, kubectl, npm, python, rust, etc.)
  │   └── Load theme (disabled, using Starship)
  ├── Environment variables
  ├── History configuration (setopt)
  ├── Zsh options
  ├── Completion styling
  ├── Key bindings
  ├── Tool integrations (similar to bash)
  ├── source ~/.zsh_aliases
  ├── source ~/.zsh_functions
  ├── _welcome_bar (time-aware greeting)
  ├── source ~/.zshrc.local (if exists)
  ├── Pyenv initialization
  └── Hyprland/Wayland environment
```

### Login vs Interactive Shells

**Bash**:
- Login shell: `.bash_profile` → `.bashrc`
- Interactive non-login: `.bashrc`
- Non-interactive: neither (scripts only read sourced files)

**Zsh**:
- Login shell: `.zlogin` (not used), `.zshrc`
- Interactive non-login: `.zshrc`
- Non-interactive: neither

## Feature Parity

### Achieved Feature Parity

Both shells now have:

1. **Identical Aliases**
   - 140+ aliases across both shells
   - Organized in same categories
   - Same behavior and naming convention

2. **Same Utility Functions**
   ```bash
   mkcd()      # mkdir + cd
   backup()    # Create .bak copy
   f()         # Find files
   ftext()     # Search text
   extract()   # Multi-format extraction
   sssh()      # SSH with completion
   cleanup()   # 7-step system cleanup
   ```

3. **Identical Environment Variables**
   - EDITOR=nvim
   - VISUAL=nvim
   - OLLAMA_NUM_CTX=16384
   - PATH, HISTSIZE, etc.

4. **Same Tool Integration**
   - NVM (Node Version Manager)
   - Cargo (Rust)
   - Zoxide (smart cd)
   - FZF (fuzzy finder)
   - TheFuck (command corrector)
   - Starship (prompt)
   - Pyenv (Python)

5. **Identical SSH Agent Management**
   - Auto-start on login
   - Persistent environment file
   - Automatic restart if crashed

### Intentional Differences

Some features are shell-optimized:

1. **Welcome Message**
   - **Bash**: CPU/RAM progress bars (system-aware)
   - **Zsh**: Time-aware greeting (interactive-aware)
   - Use `_welcome_bar` function in both (different implementations)

2. **Completion System**
   - **Bash**: COMPREPLY array (traditional)
   - **Zsh**: zstyle (modern, more powerful)
   - Both achieve similar results with shell-native mechanisms

3. **Git Aliases**
   - **Bash**: All aliases directly sourced
   - **Zsh**: Mix of Oh My Zsh plugin + custom aliases
   - Behavior identical, sourcing different

## Advanced Configuration

### History Management

#### Bash History
```bash
HISTSIZE=50000                # In-memory commands
HISTFILESIZE=100000           # On-disk commands
HISTCONTROL=ignoreboth:erasedups  # Don't save duplicates
HISTTIMEFORMAT="%F %T "       # Show timestamps
HISTIGNORE="ls:ll:la:cd:pwd:clear:history:exit"  # Skip common commands

_sync_history() {
    history -a                # Append new commands
    history -n                # Read new commands
}
PROMPT_COMMAND="_sync_history${PROMPT_COMMAND:+;${PROMPT_COMMAND}}"
```

#### Zsh History
```bash
HISTSIZE=50000                # In-memory commands
SAVEHIST=100000               # On-disk commands
setopt SHARE_HISTORY          # Share between sessions
setopt EXTENDED_HISTORY       # Save timestamps
setopt HIST_IGNORE_DUPS       # Remove duplicates
setopt HIST_REDUCE_BLANKS     # Clean up blanks
setopt HIST_IGNORE_SPACE      # Ignore commands starting with space
setopt INC_APPEND_HISTORY     # Write immediately
```

### Shell Options

#### Bash Shell Options
```bash
shopt -s cdspell              # Auto-correct cd typos
shopt -s dirspell             # Correct directory names
shopt -s globstar             # ** recursive globbing
shopt -s checkwinsize         # Update LINES/COLUMNS
shopt -s extglob              # Extended pattern matching
shopt -s histappend           # Append to history file
```

#### Zsh Shell Options
```bash
setopt AUTO_CD                # cd on directory name
setopt AUTO_PUSHD             # Push old directory on cd
setopt EXTENDED_GLOB          # Extended patterns
setopt NO_BEEP                # Disable beeps
setopt INTERACTIVE_COMMENTS   # Allow # in interactive shell
```

### Key Bindings (Zsh)

```bash
# Better history navigation
bindkey "^[[A" up-line-or-beginning-search    # Up arrow
bindkey "^[[B" down-line-or-beginning-search  # Down arrow
bindkey "^P" up-line-or-beginning-search      # Ctrl+P
bindkey "^N" down-line-or-beginning-search    # Ctrl+N

# Line navigation
bindkey "^[[H" beginning-of-line              # Home
bindkey "^[[F" end-of-line                    # End
bindkey "^[[3~" delete-char                   # Delete key
bindkey "^[[1;5C" forward-word                # Ctrl+Right
bindkey "^[[1;5D" backward-word               # Ctrl+Left
```

### FZF Configuration

```bash
export FZF_DEFAULT_OPTS="
    --height 40%
    --layout=reverse
    --border
    --inline-info
    --color=fg:#e0e0e0,bg:#1a1a2e,hl:#3282b8
    --color=fg+:#ffffff,bg+:#16213e,hl+:#00d9ff
    --color=info:#a8a8a8,prompt:#3282b8,pointer:#00d9ff
    --color=marker:#00d9ff,spinner:#3282b8,header:#3282b8
"

# Use fd for faster searching
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
```

### Starship Prompt Integration

Both shells initialize Starship identically:

```bash
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"  # Bash
    # or
    eval "$(starship init zsh)"   # Zsh
fi
```

Starship reads `~/.config/starship.toml` for customization.

## Troubleshooting

### Common Issues

#### 1. Aliases Not Loading

**Symptom**: Aliases undefined after shell start

**Bash**:
```bash
# Check if file exists
test -f ~/.bash_aliases && echo "exists" || echo "missing"

# Check if .bashrc sources it
grep "bash_aliases" ~/.bashrc

# Manually reload
source ~/.bash_aliases
```

**Zsh**:
```bash
# Same checks, but for zsh
test -f ~/.zsh_aliases && echo "exists" || echo "missing"
grep "zsh_aliases" ~/.zshrc
source ~/.zsh_aliases
```

#### 2. Functions Not Available

**Bash**:
```bash
# Check functions file
test -f ~/.bash_functions && echo "exists" || echo "missing"

# List loaded functions
declare -F | grep -E "mkcd|backup|cleanup"

# Debug sourcing
bash -x -c "source ~/.bashrc" 2>&1 | head -20
```

**Zsh**:
```bash
# Check functions file
test -f ~/.zsh_functions && echo "exists" || echo "missing"

# List loaded functions
functions | grep -E "mkcd|backup|cleanup"

# Debug sourcing
zsh -x -c "source ~/.zshrc" 2>&1 | head -20
```

#### 3. Slow Startup

**Bash** (~200ms expected):
```bash
# Profile startup
time bash -i -c exit

# Identify slow sections
bash -x -i -c exit 2>&1 | grep -oE '[0-9]+\.[0-9]+ bash' | sort -rn | head -5
```

**Zsh** (~300ms expected):
```bash
# Profile startup
time zsh -i -c exit

# Identify slow sections
zsh -x -i -c exit 2>&1 | grep -E "^\+" | head -20
```

#### 4. Tool Integration Not Working

**NVM not available**:
```bash
# Check if nvm installed
test -d ~/.nvm && echo "NVM found" || echo "NVM not installed"

# Install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Reload shell
source ~/.bashrc  # or ~/.zshrc
```

**Cargo not found**:
```bash
# Check Rust installation
rustc --version

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Reload shell
source ~/.bashrc  # or ~/.zshrc
```

**FZF not working**:
```bash
# Check if installed
command -v fzf

# Install FZF
sudo pacman -S fzf

# Or install from source
git clone https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# Test FZF
Ctrl+T  # Should open file picker
Ctrl+R  # Should open history search
```

#### 5. Git Aliases Conflicting (Zsh)

**Issue**: Zsh Oh My Zsh git aliases might conflict

**Resolution**:
```bash
# Check which alias is defined
which ga          # Should show git alias
type ga           # Shows builtin or alias

# If conflicting, check .zsh_aliases comments
grep "gap\|gcm" ~/.zsh_aliases

# Use explicit version
\ga               # Bypass alias
git add           # Use full command
```

### Performance Optimization

#### Conditional Tool Loading

All tools are conditionally loaded (only if installed):

```bash
# Example: NVM only loads if directory exists
if [[ -d "$HOME/.nvm" ]]; then
    # NVM loading code
fi

# Example: Cargo only sources if file exists
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
```

#### History Optimization

**Bash**: Uses `_sync_history` function to avoid blocking
**Zsh**: Uses `setopt SHARE_HISTORY` for true multi-session sync

#### FZF Performance

Uses `fd` (fast alternative to find):

```bash
# Much faster than default find
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'

# Install fd
sudo pacman -S fd
```

### Debug Mode

```bash
# Bash debug startup
bash -x ~/.bashrc 2>&1 | less

# Zsh debug startup
zsh -x ~/.zshrc 2>&1 | less

# Profile execution time
time bash -i -c exit
time zsh -i -c exit

# Trace function calls
set -x        # Enable
set +x        # Disable
```

## Switching Between Shells

### From Bash to Zsh

```bash
# Change default shell
chsh -s /usr/bin/zsh

# Verify change
echo $SHELL

# Log out and back in (or use 'exec zsh')
exec zsh
```

### From Zsh to Bash

```bash
# Change default shell
chsh -s /usr/bin/bash

# Verify change
echo $SHELL

# Log out and back in
exec bash
```

### Testing Without Switching

```bash
# Try bash
bash

# Try zsh
zsh

# Exit back to original
exit
```

## Custom Local Configuration

### Bash Local Overrides

Create `~/.bashrc.local` for machine-specific settings:

```bash
# ~/.bashrc.local (sourced at end of .bashrc)

# Machine-specific aliases
alias myserver='ssh user@192.168.1.100'

# Custom environment
export MY_PROJECT_PATH="/home/user/projects/myproject"

# Local functions
my_local_func() {
    echo "Only on this machine"
}
```

### Zsh Local Overrides

Create `~/.zshrc.local` for machine-specific settings:

```bash
# ~/.zshrc.local (sourced at end of .zshrc)

# Same as bash.local - machine-specific config
alias myserver='ssh user@192.168.1.100'
export MY_PROJECT_PATH="/home/user/projects/myproject"
```

### Alias Overrides

Create machine-specific alias files:

```bash
# ~/.bash_aliases.local (bash)
echo "alias myalias='custom command'" >> ~/.bash_aliases.local

# ~/.zsh_aliases.local (zsh)
echo "alias myalias='custom command'" >> ~/.zsh_aliases.local
```

Then source them in `.bashrc`/`.zshrc`:

```bash
# Add to .bashrc/.zshrc after sourcing main aliases
[[ -f ~/.bash_aliases.local ]] && source ~/.bash_aliases.local
[[ -f ~/.zsh_aliases.local ]] && source ~/.zsh_aliases.local
```

## References

- **Bash Manual**: https://www.gnu.org/software/bash/manual/
- **Zsh Manual**: http://zsh.sourceforge.net/Doc/
- **Oh My Zsh**: https://ohmyz.sh/
- **Starship**: https://starship.rs/
- **FZF**: https://github.com/junegunn/fzf
- **Catppuccin**: https://catppuccin.com/

