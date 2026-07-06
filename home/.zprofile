#
# ~/.zprofile
# Login shell configuration - runs before .zshrc
# DO NOT source .zshrc here - zsh loads it automatically

# Added by Toolbox App
export PATH="$PATH:/home/semyon/.local/share/JetBrains/Toolbox/scripts"

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# User-owned Node global install locations
export NPM_CONFIG_PREFIX="$HOME/.local"
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$HOME/.local/bin:$PNPM_HOME/bin:$PATH"
