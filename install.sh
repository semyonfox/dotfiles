#!/bin/bash

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

echo "Setting up dotfiles from $DOTFILES_DIR..."
mkdir -p "$BACKUP_DIR"

# Function to link a file
link_file() {
    local rel_path="$1"
    local src="$DOTFILES_DIR/$rel_path"
    local dest="$HOME/.$rel_path"

    # Handle cases where the file is in config/ (e.g., config/nvim maps to ~/.config/nvim)
    if [[ "$rel_path" == config/* ]]; then
        dest="$HOME/.$rel_path"
    else
        dest="$HOME/.$rel_path"
    fi

    local dest_dir="$(dirname "$dest")"
    mkdir -p "$dest_dir"

    if [ -L "$dest" ]; then
        echo "Skipping $rel_path: Already a symlink."
        return
    fi

    if [ -e "$dest" ]; then
        echo "Backing up existing $dest to $BACKUP_DIR"
        mv "$dest" "$BACKUP_DIR/"
    fi

    echo "Linking $rel_path -> $dest"
    ln -s "$src" "$dest"
}

# List of files to link (relative to dotfiles root)
# Root items (mapped to ~/.item)
link_file "bashrc"
link_file "bash_aliases"
link_file "bash_functions"
link_file "bash_profile"
link_file "profile"
link_file "gitconfig"
link_file "tmux.conf"
link_file "wezterm.lua"

# Config items (mapped to ~/.config/item)
link_file "config/starship.toml"
link_file "config/nvim"
link_file "config/ghostty"
link_file "config/kitty"
link_file "config/btop"
link_file "config/htop"
link_file "config/neofetch"

echo "Done! Old configurations backed up to $BACKUP_DIR"
