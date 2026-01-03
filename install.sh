#!/usr/bin/env bash

set -e

# Source common functions and other scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/install-deps.sh"
source "$SCRIPT_DIR/setup.sh"
source "$SCRIPT_DIR/switch-to-zsh.sh"

# Main unified installer
main() {
    echo ""
    echo "================================"
    echo "  Dotfiles Installation"
    echo "================================"
    echo ""

    local os=$(detect_os)
    info "OS: $os"

    is_wsl && {
        warn "WSL detected"
        info "Use Windows Terminal instead of Linux terminal emulators"
    }

    echo ""
    echo "This installer will guide you through:"
    echo "  1. Installing dependencies (zsh, git, tmux, neovim, CLI tools)"
    echo "  2. Deploying dotfiles with stow"
    echo "  3. Switching to zsh (optional)"
    echo ""

    read -p "Continue? (y/n) " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && error "Cancelled"

    # Step 1: Dependencies
    echo ""
    echo "--- Step 1: Dependencies ---"
    read -p "Install dependencies? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        install_core_packages
        echo ""
        read -p "Install optional tools (thefuck, pyenv)? (y/n) " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] && install_optional_tools
        echo ""
        install_tpm
    else
        command -v stow &>/dev/null || error "stow required. Install it first."
    fi

    # Step 2: Deploy dotfiles
    echo ""
    echo "--- Step 2: Deploy Dotfiles ---"
    read -p "Deploy dotfiles with stow? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        ensure_stow
        deploy_dotfiles
    fi

    # Step 3: Switch to zsh
    echo ""
    echo "--- Step 3: Shell ---"

    if ! command -v zsh &>/dev/null; then
        warn "zsh not installed - skipping shell switch"
    else
        read -p "Switch to zsh? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo ""
            local current_shell=$(basename "$SHELL")

            if [[ "$current_shell" == "zsh" ]]; then
                success "Already using zsh"
                install_omz
            else
                install_omz
                echo ""
                local zsh_path=$(command -v zsh)
                grep -q "^$zsh_path$" /etc/shells 2>/dev/null || {
                    echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
                }
                chsh -s "$zsh_path"
                success "Shell changed to zsh"
            fi
        fi
    fi

    # Done
    echo ""
    echo "================================"
    success "Installation complete!"
    echo "================================"
    echo ""
    info "Next steps:"
    echo "  1. Restart your terminal or: source ~/.zshrc"
    echo "  2. In tmux, press Ctrl-b then I to install plugins"
    is_wsl && echo "  3. Configure Windows Terminal with a Nerd Font"
    echo ""
}

main "$@"
