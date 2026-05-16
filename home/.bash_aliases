# ======================================================================
# ALIASES - NAVIGATION
# ======================================================================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

# ======================================================================
# ALIASES - FILE LISTING
# ======================================================================
# Use eza if available, otherwise fallback to ls
if command -v eza &>/dev/null; then
    alias ls='eza --icons --git'
    alias ll='eza --icons --git -lha'
    alias la='eza --icons --git -a'
    alias l='eza --icons --git'
    alias lt='eza --icons --git -lha --sort=modified'
    alias tree='eza --icons --git --tree'
else
    alias ls='ls --color=auto'
    alias ll='ls -lha --color=auto'
    alias la='ls -A --color=auto'
    alias l='ls -CF --color=auto'
    alias lt='ls -lhtra --color=auto'
    alias tree='tree -C'
fi

# Use bat if available
command -v bat &>/dev/null && alias cat='bat'

# ======================================================================
# ALIASES - UTILITIES
# ======================================================================
alias c='clear'
alias h='history'
alias ports='ss -tulanp'
alias myip='curl -s ifconfig.me'
alias localip="ip -o -4 addr show | awk '{print \$4}' | cut -d/ -f1"
alias df='df -h'
alias du='du -h'
# update is defined as a function in .bash_functions

# Safe operations
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

# App shortcuts
alias todo='dooit'
alias pomodoro='pomodoro-tui'
alias gcheck='gaming-check'
alias gmodes='gaming-modes'
alias pplus='protonplus'

# ======================================================================
# ALIASES - DOCKER
# ======================================================================
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dexec='docker exec -it'
alias dlogs='docker logs -f'
alias dstop='docker stop'
alias drm='docker rm'
alias dprune='docker system prune -af'

# ======================================================================
# ALIASES - GIT
# ======================================================================
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gap='git add -p'
alias gb='git branch'
alias gbr='git branch -r'
alias gba='git branch -a'
alias gc='git commit -m'
alias gca='git commit -am'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gcp='git cherry-pick'
alias gd='git diff'
alias gds='git diff --staged'
alias gf='git fetch'
alias gfa='git fetch --all --prune'
alias gl='git log --oneline --graph --decorate'
alias gll='git log --graph --pretty=format:"%C(yellow)%h%C(reset) -%C(auto)%d%C(reset) %s %C(green)(%cr) %C(bold blue)<%an>%C(reset)"'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpo='git push origin'
alias gpu='git push --set-upstream origin'
alias gr='git rebase'
alias gri='git rebase -i'
alias grs='git reset'
alias grh='git reset --hard'
alias gs='git status -sb'
alias gst='git status'
alias gsh='git show'
alias gss='git stash'
alias gsp='git stash pop'
alias gsa='git stash apply'
alias gsl='git stash list'
alias gsu='git submodule update --init --recursive'
alias gt='git tag'

# ======================================================================
# ALIASES - NEOVIM/EDITOR
# ======================================================================
alias v='nvim'
alias vi='nvim'
alias vim='nvim'
alias e='$EDITOR'                  # Use configured editor

# Quick config access
alias vconf='nvim ~/.config/nvim'
alias bashrc='nvim ~/.bashrc'
alias balias='nvim ~/.bash_aliases'
alias zshrc='nvim ~/.zshrc'
alias zalias='nvim ~/.zsh_aliases'
alias tconf='nvim ~/.tmux.conf'

# ======================================================================
# ALIASES - TMUX
# ======================================================================
alias t='tmux'
alias ta='tmux attach'
alias tat='tmux attach -t'
alias tns='tmux new-session -s'
alias tls='tmux list-sessions'
alias tks='tmux kill-session -t'

# ======================================================================
# ALIASES - LAZYGIT
# ======================================================================
alias lg='lazygit'

# ======================================================================
# ALIASES - SHELL
# ======================================================================
alias reload='source ~/.bashrc'

# ======================================================================
# ALIASES - AI TOOLS
# ======================================================================
alias cc='CLAUDE_CODE_NO_FLICKER=1 LS_DEMO=1 CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 CLAUDE_CODE_DISABLE_1M_CONTEXT=1 claude --dangerously-skip-permissions'
alias cx='codex --yolo'
alias oc='opencode --dangerously-skip-permissions'
