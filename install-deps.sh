#!/usr/bin/env bash

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Install core packages
install_core_packages() {
    local os=$(detect_os)
    local base_os=$(get_base_os)

    info "Installing core packages for $os..."

    case "$base_os" in
        arch|endeavouros|manjaro)
            sudo pacman -S --needed --noconfirm \
                zsh zsh-completions git tmux neovim curl wget base-devel \
                eza bat fd ripgrep fzf zoxide starship
            ;;

        ubuntu|debian|pop|linuxmint)
            sudo apt update
            sudo apt install -y \
                zsh git tmux neovim curl wget build-essential \
                fd-find ripgrep fzf

            # bat (different package name on older Ubuntu)
            if apt-cache show bat &>/dev/null; then
                sudo apt install -y bat
            else
                sudo apt install -y batcat
                mkdir -p ~/.local/bin
                ln -sf $(which batcat) ~/.local/bin/bat 2>/dev/null || true
            fi

            # Install via scripts
            command -v zoxide &>/dev/null || curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
            command -v starship &>/dev/null || curl -sS https://starship.rs/install.sh | sh -s -- -y
            ;;

        fedora|rhel|centos)
            sudo dnf install -y \
                zsh git tmux neovim curl wget @development-tools \
                eza bat fd-find ripgrep fzf zoxide

            command -v starship &>/dev/null || curl -sS https://starship.rs/install.sh | sh -s -- -y
            ;;

        opensuse*)
            sudo zypper install -y \
                zsh git tmux neovim curl wget patterns-devel-base-devel_basis \
                bat fd ripgrep fzf

            command -v zoxide &>/dev/null || curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
            command -v starship &>/dev/null || curl -sS https://starship.rs/install.sh | sh -s -- -y
            ;;

        macos)
            command -v brew &>/dev/null || error "Homebrew required. Install from https://brew.sh"

            brew install \
                zsh git tmux neovim curl wget \
                eza bat fd ripgrep fzf zoxide starship
            ;;

        *)
            error "Unsupported OS: $os"
            ;;
    esac

    success "Core packages installed"
}

# Install optional tools
install_optional_tools() {
    local base_os=$(get_base_os)

    echo ""
    read -p "Install thefuck? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] && ! command -v thefuck &>/dev/null; then
        case "$base_os" in
            arch|endeavouros|manjaro)
                sudo pacman -S --needed --noconfirm python python-pip ;;
        esac
        pip install --user thefuck || pip3 install --user thefuck
        success "thefuck installed"
    fi

    echo ""
    read -p "Install pyenv? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] && ! command -v pyenv &>/dev/null; then
        curl https://pyenv.run | bash
        success "pyenv installed"
    fi
}

# Install TPM
install_tpm() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"

    if [[ -d "$tpm_dir" ]]; then
        success "TPM already installed"
        return 0
    fi

    info "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
    success "TPM installed - press 'prefix + I' in tmux to install plugins"
}

# Main function
main() {
    echo ""
    echo "================================"
    echo "  Dependencies Installation"
    echo "================================"
    echo ""

    local os=$(detect_os)
    info "OS: $os"

    is_wsl && warn "WSL detected - terminal emulators not needed"

    echo ""
    read -p "Install core packages? (y/n) " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && install_core_packages

    echo ""
    read -p "Install optional tools? (y/n) " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && install_optional_tools

    echo ""
    install_tpm

    echo ""
    success "Dependencies installed!"
    echo ""
    info "Next: run ./setup.sh to deploy dotfiles"
    echo ""
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
