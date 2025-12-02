#!/usr/bin/env bash

set -e # Exit immediately if a command exits with a non-zero status.

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
BACKUP_CREATED=false

echo "🚀 Setting up dotfiles from $DOTFILES_DIR..."

# Files and directories to ignore in the root directory
IGNORE_FILES=(
  ".git"
  ".gitignore"
  ".editorconfig"
  "install.sh"
  "README.md"
  "LICENSE"
  "config" # Handled separately
)

# Helper function to check if an element exists in an array
contains_element() {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

# Function to create a symlink
create_link() {
    local src="$1"
    local dest="$2"
    
    # Create destination directory if it doesn't exist
    mkdir -p "$(dirname "$dest")"

    # Check if the link already exists and points to the correct source
    if [ -L "$dest" ]; then
        local current_link
        current_link="$(readlink "$dest")"
        if [ "$current_link" == "$src" ]; then
            echo "  ✅ $dest is already linked correctly."
            return
        fi
    fi

    # Backup existing file, directory, or link if it exists
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        if [ "$BACKUP_CREATED" = false ]; then
            mkdir -p "$BACKUP_DIR"
            BACKUP_CREATED=true
            echo "  📦 Backup directory created: $BACKUP_DIR"
        fi
        echo "  ↪️  Backing up existing $(basename "$dest")"
        mv "$dest" "$BACKUP_DIR/"
    fi

    echo "  🔗 Linking $(basename "$src") -> $dest"
    ln -s "$src" "$dest"
}

# 1. Link root-level files to $HOME/.<filename>
echo "📂 Processing root config files..."
for file in "$DOTFILES_DIR"/*; do
    # Check if glob matched anything
    [ -e "$file" ] || continue
    
    filename="$(basename "$file")"
    
    # Skip explicitly ignored files
    if contains_element "$filename" "${IGNORE_FILES[@]}"; then
        continue
    fi

    create_link "$file" "$HOME/.$filename"
done

# 2. Link config/ directory items to $HOME/.config/<filename>
echo "📂 Processing .config directory..."
if [ -d "$DOTFILES_DIR/config" ]; then
    mkdir -p "$HOME/.config"
    for file in "$DOTFILES_DIR/config"/*; do
        # Check if glob matched anything
        [ -e "$file" ] || continue
        
        filename="$(basename "$file")"
        create_link "$file" "$HOME/.config/$filename"
    done
fi

echo "✨ Dotfiles setup complete!"
if [ "$BACKUP_CREATED" = true ]; then
    echo "📁 Old configurations were backed up to $BACKUP_DIR"
fi