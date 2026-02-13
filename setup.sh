#!/usr/bin/env bash

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Globals
DRY_RUN=false
BACKUP_DIR=""

# Rollback on error
rollback() {
    if [[ -n "$BACKUP_DIR" && -d "$BACKUP_DIR" ]]; then
        warn "Rolling back changes..."
        cd "$SCRIPT_DIR"
        stow -D home 2>/dev/null || true

        if [[ -n "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
            cp -r "$BACKUP_DIR"/* "$HOME/" 2>/dev/null || true
            cp -r "$BACKUP_DIR"/.* "$HOME/" 2>/dev/null || true
            success "Restored files from backup"
        fi

        error "Setup failed. Original files restored."
    else
        error "Setup failed. No backup to restore."
    fi
}

trap rollback ERR

# Install stow if needed
ensure_stow() {
    if command -v stow &>/dev/null; then
        return 0
    fi

    local os=$(detect_os)
    local base_os=$(get_base_os)

    info "Installing stow..."

    case "$base_os" in
        arch|endeavouros|manjaro|cachyos)
            sudo pacman -S --noconfirm stow ;;
        ubuntu|debian|pop|linuxmint)
            sudo apt update && sudo apt install -y stow ;;
        fedora|rhel|centos)
            sudo dnf install -y stow ;;
        opensuse*)
            sudo zypper install -y stow ;;
        macos)
            command -v brew &>/dev/null || error "Homebrew required. Install from https://brew.sh"
            brew install stow ;;
        *)
            error "Unsupported OS: $os. Install stow manually." ;;
    esac

    success "stow installed"
}

# Backup existing dotfiles
backup_existing() {
    BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    local files_to_backup=()

    local dotfiles=(.bashrc .bash_aliases .bash_functions .bash_profile .zshrc .zsh_aliases .zsh_functions .zprofile .profile .gitconfig .tmux.conf .wezterm.lua)

    for file in "${dotfiles[@]}"; do
        if [[ -f "$HOME/$file" && ! -L "$HOME/$file" ]]; then
            files_to_backup+=("$file")
        fi
    done

    local config_items=(btop ghostty htop kitty neofetch starship.toml)
    for item in "${config_items[@]}"; do
        if [[ -e "$HOME/.config/$item" && ! -L "$HOME/.config/$item" ]]; then
            files_to_backup+=(".config/$item")
        fi
    done

    if [[ ${#files_to_backup[@]} -eq 0 ]]; then
        info "No conflicting files found"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY RUN] Would backup ${#files_to_backup[@]} files to $BACKUP_DIR"
        return 0
    fi

    warn "Found ${#files_to_backup[@]} conflicting files"
    read -p "Backup these files? (y/n) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mkdir -p "$BACKUP_DIR"
        for file in "${files_to_backup[@]}"; do
            local backup_path="$BACKUP_DIR/$file"
            mkdir -p "$(dirname "$backup_path")"
            mv "$HOME/$file" "$backup_path"
        done
        success "Backup created at $BACKUP_DIR"
    else
        error "Cannot proceed with existing files"
    fi
}

# Deploy dotfiles
deploy_dotfiles() {
    info "Deploying dotfiles from $SCRIPT_DIR"
    cd "$SCRIPT_DIR"

    if stow -n home 2>&1 | grep -q "conflict"; then
        warn "Conflicts detected"
        backup_existing
    fi

    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY RUN] Simulating deployment..."
        stow -n -v home
        return 0
    fi

    stow home
    success "Dotfiles deployed"
}

# Verify installation
verify_installation() {
    info "Verifying installation..."

    local verified=0
    local failed=0
    local dotfiles=(.bashrc .zshrc .gitconfig .tmux.conf .wezterm.lua)

    for file in "${dotfiles[@]}"; do
        if [[ -L "$HOME/$file" ]]; then
            ((verified++))
        else
            ((failed++))
        fi
    done

    echo "  Verified: $verified"
    [[ $failed -gt 0 ]] && echo "  Missing: $failed"
}

# Main function
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run|-n)
                DRY_RUN=true
                shift ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --dry-run, -n    Simulate without making changes"
                echo "  --help, -h       Show this help"
                exit 0 ;;
            *)
                error "Unknown option: $1" ;;
        esac
    done

    echo ""
    echo "================================"
    echo "  Dotfiles Setup (stow only)"
    echo "================================"
    echo ""

    [[ "$DRY_RUN" == true ]] && warn "DRY RUN MODE"

    ensure_stow
    echo ""
    deploy_dotfiles
    echo ""

    if [[ "$DRY_RUN" == false ]]; then
        verify_installation
        trap - ERR
        echo ""
        success "Setup complete!"
        info "Restart terminal or run: source ~/.bashrc"
    else
        success "Dry run complete"
    fi
    echo ""
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
