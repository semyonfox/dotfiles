#!/usr/bin/env bash

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Install oh-my-zsh
install_omz() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        success "oh-my-zsh already installed"
        return 0
    fi

    read -p "Install oh-my-zsh? (recommended) (y/n) [y] " -n 1 -r
    echo
    REPLY=${REPLY:-y}

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Installing oh-my-zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        success "oh-my-zsh installed"
    fi
}

# Main function
main() {
    echo ""
    echo "================================"
    echo "  Switch to Zsh Shell"
    echo "================================"
    echo ""

    if ! command -v zsh &>/dev/null; then
        error "zsh not installed. Run: sudo pacman -S zsh zsh-completions"
    fi

    success "zsh is installed at: $(command -v zsh)"

    local current_shell=$(basename "$SHELL")
    info "Current shell: $current_shell"

    if [[ "$current_shell" == "zsh" ]]; then
        success "Already using zsh"
        echo ""
        install_omz
        exit 0
    fi

    local zsh_path=$(command -v zsh)

    if ! grep -q "^$zsh_path$" /etc/shells 2>/dev/null; then
        warn "Adding $zsh_path to /etc/shells"
        echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi

    echo ""
    info "This will change your default shell to zsh"
    info "You'll need to log out and back in for changes to take effect"
    echo ""

    read -p "Continue? (y/n) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_omz
        echo ""
        chsh -s "$zsh_path"
        success "Default shell changed to zsh"
        echo ""
        info "Next steps:"
        echo "  1. Log out and log back in"
        echo "  2. Your zsh configs are ready via stow"
        echo ""
    else
        info "Cancelled"
    fi
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
