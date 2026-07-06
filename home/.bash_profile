#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc


# Added by Toolbox App
export PATH="$PATH:/home/semyon/.local/share/JetBrains/Toolbox/scripts"

[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

[[ -f "$HOME/.local/share/../bin/env" ]] && . "$HOME/.local/share/../bin/env"
