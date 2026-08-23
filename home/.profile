

# Added by Toolbox App
export PATH="$PATH:/home/semyon/.local/share/JetBrains/Toolbox/scripts"

[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# User-owned Node global install locations
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$HOME/.local/bin:$PNPM_HOME/bin:$PATH"

[[ -f "$HOME/.local/share/../bin/env" ]] && . "$HOME/.local/share/../bin/env"


# Added by Antigravity CLI installer
export PATH="/home/semyon/.local/bin:$PATH"
