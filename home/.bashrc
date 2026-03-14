#!/usr/bin/env bash
# ~/.bashrc - Bash configuration for interactive shells
# Configuration based on Oh My Bash patterns and community best practices

# ======================================================================
# INTERACTIVE SHELL CHECK
# ======================================================================
[[ $- != *i* ]] && return

# ======================================================================
# ENVIRONMENT VARIABLES
# ======================================================================
export PATH="$HOME/.local/bin:$PATH"
export EDITOR='nvim'
export VISUAL='nvim'
export OLLAMA_NUM_CTX=16384   # 16k context window for Ollama models

# ======================================================================
# HISTORY CONFIGURATION
# ======================================================================
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups
HISTTIMEFORMAT="%F %T "
HISTIGNORE="ls:ll:la:cd:pwd:clear:history:exit"

shopt -s histappend

# Sync history across sessions
_sync_history() {
    history -a
    history -n
}
PROMPT_COMMAND="_sync_history${PROMPT_COMMAND:+;${PROMPT_COMMAND}}"

# ======================================================================
# SHELL OPTIONS
# ======================================================================
shopt -s cdspell        # Auto-correct minor spelling errors in cd
shopt -s dirspell       # Auto-correct directory names during completion
shopt -s globstar       # Enable ** recursive globbing
shopt -s checkwinsize   # Update LINES and COLUMNS after each command
shopt -s extglob        # Enable extended pattern matching

# ======================================================================
# BASH COMPLETION
# ======================================================================
if ! shopt -oq posix; then
    for completion_file in \
        /usr/share/bash-completion/bash_completion \
        /etc/bash_completion; do
        [[ -f "$completion_file" ]] && source "$completion_file" && break
    done
fi

# ======================================================================
# COLOR SUPPORT
# ======================================================================
if [[ -x /usr/bin/dircolors ]]; then
    if [[ -r ~/.dircolors ]]; then
        eval "$(dircolors -b ~/.dircolors)"
    else
        eval "$(dircolors -b)"
    fi
fi

[[ -x /usr/bin/lesspipe ]] && eval "$(SHELL=/bin/sh lesspipe)"

# ======================================================================
# TOOL INTEGRATIONS
# ======================================================================

# Node Version Manager
if [[ -d "$HOME/.nvm" ]]; then
    export NVM_DIR="$HOME/.nvm"
    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
    [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
fi

# Rust/Cargo
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Zoxide - Smarter cd
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash)"
    alias cdi='zi'

    # Override cd to use zoxide when appropriate
    cd() {
        if [[ $# -eq 0 ]]; then
            builtin cd ~
        elif [[ $# -eq 1 ]] && zoxide query -- "$1" &>/dev/null; then
            builtin cd "$(zoxide query -- "$1")"
        else
            builtin cd "$@"
        fi
    }
fi

# FZF - Fuzzy Finder
if [[ -f ~/.fzf.bash ]]; then
    source ~/.fzf.bash

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

    # Use fd if available for better performance
    if command -v fd &>/dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi

    # Custom history search with fzf
    _fzf_hist() {
        local selected
        selected="$(history | tac | awk '{$1=""; print substr($0,2)}' | fzf --tiebreak=index)"
        READLINE_LINE="$selected"
        READLINE_POINT="${#selected}"
    }
    bind -x '"\C-r": _fzf_hist'
fi

# TheFuck - Command corrector
if command -v thefuck &>/dev/null; then
    eval "$(thefuck --alias)"
    eval "$(thefuck --alias f)"
fi

# Starship Prompt
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi

# ======================================================================
# SSH AGENT MANAGEMENT
# ======================================================================
_ssh_agent_env="$HOME/.ssh/agent-environment"

_start_ssh_agent() {
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "$_ssh_agent_env"
    chmod 600 "$_ssh_agent_env"
    source "$_ssh_agent_env" &>/dev/null
}

if [[ -f "$_ssh_agent_env" ]]; then
    source "$_ssh_agent_env" &>/dev/null
    ps -p "$SSH_AGENT_PID" 2>/dev/null | grep -q ssh-agent || _start_ssh_agent
else
    _start_ssh_agent
fi

# ======================================================================
# ALIASES - Bash git aliases adapted from Oh My Bash conventions
# ======================================================================
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi


# ======================================================================
# FUNCTIONS - Utility functions for daily workflows
# ======================================================================
if [ -f ~/.bash_functions ]; then
    . ~/.bash_functions
fi

# Show welcome message on shell start
_welcome_bar

# ======================================================================
# LOCAL OVERRIDES
# ======================================================================
# Source local bashrc if it exists (for machine-specific configs)
[[ -f ~/.bashrc.local ]] && source ~/.bashrc.local
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# ======================================================================
# GAMING & DEVELOPMENT ENVIRONMENT (Hyprland/Wayland)
# ======================================================================
# Steam/Proton fixes for Hyprland Wayland
export PROTON_LOG=0                           # set to 1 for debug logs
export WINE_CPU_TOPOLOGY=4:2                  # optimize for quad-core systems
export STAGING_SHARED_MEMORY=1                # enable shared memory for Proton
export STEAM_RUNTIME_LAUNCH_DEBUG=0           # set to 1 for Steam launch debug
export SDL_VIDEODRIVER=wayland                # prefer Wayland for SDL2 apps

# PyCharm/JetBrains on Hyprland (uses QT_QPA_PLATFORM from Hyprland)
# If PyCharm crashes, temporarily use: QT_QPA_PLATFORM=xcb pycharm

# Zed alias
alias zed=zeditor
. "$HOME/.cargo/env"
