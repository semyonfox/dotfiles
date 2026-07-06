#!/usr/bin/env bash
# Enhanced dependency installation with transparency and user choice

set -e

# Source common functions and package lists
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/package-lists.sh"

# ======================================================================
# CONFIGURATION
# ======================================================================

# What the user wants to install (built during prompts)
declare -a PACKAGES_TO_INSTALL=()
INSTALL_ZSH="false"
INSTALL_OMZ="false"
INSTALL_NVM="false"
INSTALL_PYENV="false"
INSTALL_RUSTUP="false"
INSTALL_HYPRLAND="false"
INSTALL_GAMING="false"
INSTALL_LUTRIS="false"

PKG_MANAGER=""
INSTALL_CMD=""

# ======================================================================
# SYSTEM DETECTION & SETUP
# ======================================================================

show_system_info() {
    local os=$(detect_os)
    local base_os=$(get_base_os)
    PKG_MANAGER=$(detect_package_manager)
    INSTALL_CMD=$(get_install_command "$PKG_MANAGER")
    
    info "Operating System: $os"
    info "Base OS: $base_os"
    info "Package Manager: $PKG_MANAGER"
    
    if is_wsl; then
        warn "WSL2 detected - desktop packages (Hyprland, Waybar) will be skipped"
    fi
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        warn "macOS detected - desktop packages (Hyprland, Waybar) will be skipped"
    fi
    
    log "OS: $os | Package Manager: $PKG_MANAGER"
}

# ======================================================================
# INTERACTIVE PROMPTS
# ======================================================================

prompt_shell_choice() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔧 SHELL SELECTION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Which shell would you like to use?"
    echo "  [1] Bash (POSIX-compatible, lightweight)"
    echo "  [2] Zsh (modern shell with Oh My Zsh support)"
    echo ""
    read -r -p "Choice [1/2]: " choice
    echo ""
    
    case "$choice" in
        2)
            INSTALL_ZSH="true"
            PACKAGES_TO_INSTALL+=("zsh")
            info "Selected: Zsh"
            
            # Offer Oh My Zsh if zsh being installed
            echo ""
            read -r -p "Install Oh My Zsh framework? (y/n): " omz_choice
            echo ""
            if [[ $omz_choice =~ ^[Yy]$ ]]; then
                INSTALL_OMZ="true"
                info "Will install: Oh My Zsh"
            fi
            ;;
        *)
            info "Selected: Bash (default)"
            ;;
    esac
    
    log "Shell choice: $([ "$INSTALL_ZSH" = true ] && echo "zsh" || echo "bash")"
}

prompt_optional_alias_tools() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✨ OPTIONAL ALIAS TOOLS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Install optional tools referenced in aliases?"
    echo "These add convenience but aren't required:"
    echo ""
    echo "  • lazygit - Git TUI (lg alias)"
    echo "  • dooit - Todo manager (todo alias)"
    echo "  • pomodoro-tui - Timer (pomodoro alias)"
    echo "  • thefuck - Command corrector (fuck alias)"
    echo ""
    read -r -p "Install optional alias tools? (y/n): " choice
    echo ""
    
    if [[ $choice =~ ^[Yy]$ ]]; then
        PACKAGES_TO_INSTALL+=("${SHELL_OPTIONAL_PACKAGES[@]}")
        info "Will install: optional alias tools"
        log "Installing optional alias tools: ${SHELL_OPTIONAL_PACKAGES[*]}"
    else
        warn "Skipped optional alias tools - corresponding aliases may not work"
        log "Skipped optional alias tools"
    fi
}

prompt_development_tools() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💻 DEVELOPMENT TOOLS (Optional)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Install version managers?"
    echo ""
    echo "  • nvm - Node version manager"
    echo "  • pyenv - Python version manager"
    echo "  • rustup - Rust toolchain"
    echo ""
    read -r -p "Install development tools? (y/n): " choice
    echo ""
    
    if [[ $choice =~ ^[Yy]$ ]]; then
        PACKAGES_TO_INSTALL+=("${DEVELOPMENT_PACKAGES[@]}")
        INSTALL_NVM="true"
        INSTALL_PYENV="true"
        INSTALL_RUSTUP="true"
        info "Will install: development tools"
        log "Installing development tools: ${DEVELOPMENT_PACKAGES[*]}"
    else
        warn "Skipped development tools"
        log "Skipped development tools"
    fi
}

prompt_hyprland() {
    # Skip if WSL or macOS
    if is_wsl || [[ "$OSTYPE" == "darwin"* ]]; then
        return 0
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🖥️  DESKTOP ENVIRONMENT (Optional)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "This system supports Wayland desktop environment."
    echo "Install Hyprland + Waybar + Swaync?"
    echo ""
    echo "  • Hyprland - Wayland window manager"
    echo "  • Waybar - Status bar"
    echo "  • Swaync - Notification daemon"
    echo ""
    read -r -p "Install Hyprland desktop? (y/n): " choice
    echo ""
    
    if [[ $choice =~ ^[Yy]$ ]]; then
        PACKAGES_TO_INSTALL+=("${HYPRLAND_PACKAGES[@]}" "${WAYBAR_PACKAGES[@]}" "${SWAYNC_PACKAGES[@]}")
        INSTALL_HYPRLAND="true"
        info "Will install: Hyprland, Waybar, Swaync"
        log "Installing Hyprland desktop environment"
    else
        warn "Skipped desktop environment"
        log "Skipped desktop environment"
    fi
}

prompt_gaming() {
    if is_wsl || [[ "$OSTYPE" == "darwin"* ]]; then
        return 0
    fi

    case "$(get_base_os)" in
        arch|cachyos|endeavouros|manjaro)
            ;;
        *)
            warn "Skipped Linux gaming stack prompt on unsupported distro"
            return 0
            ;;
    esac

    if [[ -z "$PKG_MANAGER" ]]; then
        return 0
    fi

    local pkg
    local missing_pkg=""

    case "$PKG_MANAGER" in
        paru|yay)
            for pkg in "${GAMING_PACKAGES[@]}"; do
                if ! "$PKG_MANAGER" -Si "$pkg" &>/dev/null; then
                    missing_pkg="$pkg"
                    break
                fi
            done
            ;;
        pacman)
            for pkg in "${GAMING_PACKAGES[@]}"; do
                if ! pacman -Si "$pkg" &>/dev/null; then
                    missing_pkg="$pkg"
                    break
                fi
            done
            ;;
        *)
            warn "Skipped Linux gaming stack prompt on unsupported package manager"
            return 0
            ;;
    esac

    if [[ -n "$missing_pkg" ]]; then
        warn "Skipped Linux gaming stack prompt - $missing_pkg is unavailable with $PKG_MANAGER on this system"
        return 0
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎮 LINUX GAMING (Optional)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Install a Proton-first gaming stack?"
    echo ""
    echo "  • steam - Steam client"
    echo "  • heroic-games-launcher-bin - Epic launcher"
    echo "  • protonplus - install Proton-GE and Wine-GE"
    echo "  • umu-launcher - Proton outside Steam"
    echo "  • gamescope - fullscreen and scaling wrapper"
    echo "  • mangohud - FPS and frametime overlay"
    echo "  • gamemode + lib32-gamemode - game performance hooks"
    echo ""
    read -r -p "Install Linux gaming stack? (y/n): " choice
    echo ""

    if [[ $choice =~ ^[Yy]$ ]]; then
        PACKAGES_TO_INSTALL+=("${GAMING_PACKAGES[@]}")
        INSTALL_GAMING="true"
        info "Will install: Steam + Heroic Proton-first gaming stack"

        echo ""
        read -r -p "Also install Lutris for edge-case launchers? (y/n): " lutris_choice
        echo ""

        if [[ $lutris_choice =~ ^[Yy]$ ]]; then
            PACKAGES_TO_INSTALL+=("${GAMING_OPTIONAL_PACKAGES[@]}")
            INSTALL_LUTRIS="true"
            info "Will install: Lutris"
        else
            warn "Skipping Lutris - Heroic + Steam remain the primary setup"
        fi
    else
        warn "Skipped Linux gaming stack"
    fi
}

# ======================================================================
# PRE-INSTALL SUMMARY
# ======================================================================

show_pre_install_summary() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              PRE-INSTALLATION SUMMARY                      ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📦 PACKAGES SELECTED (Total: ${#PACKAGES_TO_INSTALL[@]})"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    local pkg_list_formatted=""
    {
        echo "[CRITICAL]"
        for pkg in "${CRITICAL_PACKAGES[@]}"; do
            [[ " ${PACKAGES_TO_INSTALL[@]} " =~ " ${pkg} " ]] && echo "  ✓ $pkg"
        done
        
        echo ""
        echo "[SHELL - CORE]"
        for pkg in "${SHELL_CORE_PACKAGES[@]}"; do
            [[ " ${PACKAGES_TO_INSTALL[@]} " =~ " ${pkg} " ]] && echo "  ✓ $pkg"
        done
        
        echo ""
        echo "[SHELL - UTILITIES]"
        for pkg in "${SHELL_UTILITY_PACKAGES[@]}"; do
            [[ " ${PACKAGES_TO_INSTALL[@]} " =~ " ${pkg} " ]] && echo "  ✓ $pkg"
        done
        
        if [[ ${#SHELL_OPTIONAL_PACKAGES[@]} -gt 0 ]]; then
            echo ""
            echo "[SHELL - OPTIONAL]"
            for pkg in "${SHELL_OPTIONAL_PACKAGES[@]}"; do
                [[ " ${PACKAGES_TO_INSTALL[@]} " =~ " ${pkg} " ]] && echo "  ✓ $pkg"
            done
        fi
        
        if [[ ${#HYPRLAND_PACKAGES[@]} -gt 0 ]] && [[ " ${PACKAGES_TO_INSTALL[@]} " =~ " ${HYPRLAND_PACKAGES[0]} " ]]; then
            echo ""
            echo "[DESKTOP - HYPRLAND]"
            for pkg in "${HYPRLAND_PACKAGES[@]}"; do
                [[ " ${PACKAGES_TO_INSTALL[@]} " =~ " ${pkg} " ]] && echo "  ✓ $pkg"
            done
            
            echo ""
            echo "[DESKTOP - WAYBAR]"
            for pkg in "${WAYBAR_PACKAGES[@]}"; do
                [[ " ${PACKAGES_TO_INSTALL[@]} " =~ " ${pkg} " ]] && echo "  ✓ $pkg"
            done
            
            echo ""
            echo "[DESKTOP - NOTIFICATIONS]"
            for pkg in "${SWAYNC_PACKAGES[@]}"; do
                [[ " ${PACKAGES_TO_INSTALL[@]} " =~ " ${pkg} " ]] && echo "  ✓ $pkg"
            done
        fi
        
        if [[ ${#DEVELOPMENT_PACKAGES[@]} -gt 0 ]]; then
            echo ""
            echo "[DEVELOPMENT]"
            for pkg in "${DEVELOPMENT_PACKAGES[@]}"; do
                [[ " ${PACKAGES_TO_INSTALL[@]} " =~ " ${pkg} " ]] && echo "  ✓ $pkg"
            done
        fi

        if [[ ${#GAMING_PACKAGES[@]} -gt 0 ]] && [[ " ${PACKAGES_TO_INSTALL[@]} " =~ " ${GAMING_PACKAGES[0]} " ]]; then
            echo ""
            echo "[GAMING - CORE]"
            for pkg in "${GAMING_PACKAGES[@]}"; do
                [[ " ${PACKAGES_TO_INSTALL[@]} " =~ " ${pkg} " ]] && echo "  ✓ $pkg"
            done
        fi

        if [[ ${#GAMING_OPTIONAL_PACKAGES[@]} -gt 0 ]]; then
            local printed_gaming_optional="false"
            for pkg in "${GAMING_OPTIONAL_PACKAGES[@]}"; do
                if [[ " ${PACKAGES_TO_INSTALL[@]} " =~ " ${pkg} " ]]; then
                    [[ "$printed_gaming_optional" == "false" ]] && {
                        echo ""
                        echo "[GAMING - OPTIONAL]"
                        printed_gaming_optional="true"
                    }
                    echo "  ✓ $pkg"
                fi
            done
        fi
    } | less -R
}

# ======================================================================
# INSTALLATION
# ======================================================================

install_packages() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║            STARTING INSTALLATION                          ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Install CRITICAL packages (exit on failure)
    info "Installing critical packages..."
    for pkg in "${CRITICAL_PACKAGES[@]}"; do
        install_package_critical "$pkg" "$PKG_MANAGER" "$INSTALL_CMD"
    done
    
    # Install SHELL CORE packages (exit on failure)
    info "Installing shell core packages..."
    for pkg in "${SHELL_CORE_PACKAGES[@]}"; do
        install_package_critical "$pkg" "$PKG_MANAGER" "$INSTALL_CMD"
    done
    
    # Install SHELL UTILITIES packages (exit on failure)
    info "Installing shell utilities..."
    for pkg in "${SHELL_UTILITY_PACKAGES[@]}"; do
        install_package_critical "$pkg" "$PKG_MANAGER" "$INSTALL_CMD"
    done
    
    # Install optional packages in user's list (continue on failure)
    local remaining_packages=()
    for pkg in "${PACKAGES_TO_INSTALL[@]}"; do
        # Skip already installed (critical and core)
        if [[ ! " ${CRITICAL_PACKAGES[@]} ${SHELL_CORE_PACKAGES[@]} ${SHELL_UTILITY_PACKAGES[@]} " =~ " ${pkg} " ]]; then
            remaining_packages+=("$pkg")
        fi
    done
    
    if [[ ${#remaining_packages[@]} -gt 0 ]]; then
        info "Installing optional packages..."
        for pkg in "${remaining_packages[@]}"; do
            install_package_optional "$pkg" "$PKG_MANAGER" "$INSTALL_CMD"
        done
    fi
}

# ======================================================================
# POST-INSTALL SETUP
# ======================================================================

post_install_setup() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔧 POST-INSTALL SETUP"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Install TPM (Tmux Plugin Manager)
    if command -v tmux &>/dev/null; then
        local tpm_dir="$HOME/.tmux/plugins/tpm"
        if [[ ! -d "$tpm_dir" ]]; then
            info "Installing Tmux Plugin Manager (TPM)..."
            mkdir -p "$HOME/.tmux/plugins"
            if git clone https://github.com/tmux-plugins/tpm "$tpm_dir" >> "$LOG_FILE" 2>&1; then
                success "TPM installed"
                info "Press 'prefix + I' in tmux to install plugins"
            else
                warn "Failed to install TPM"
            fi
        else
            success "TPM already installed"
        fi
    fi
    
    # Install Oh My Zsh (if selected)
    if [[ "$INSTALL_OMZ" == "true" ]]; then
        if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
            info "Installing Oh My Zsh..."
            if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >> "$LOG_FILE" 2>&1; then
                success "Oh My Zsh installed"
            else
                warn "Failed to install Oh My Zsh"
            fi
        else
            success "Oh My Zsh already installed"
        fi
    fi
    
    echo ""
}

# ======================================================================
# MAIN
# ======================================================================

main() {
    clear
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║      DOTFILES DEPENDENCY INSTALLATION                     ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Setup logging
    setup_logging
    
    # Show system info
    show_system_info
    
    # Add critical and core packages (always)
    PACKAGES_TO_INSTALL+=("${CRITICAL_PACKAGES[@]}")
    PACKAGES_TO_INSTALL+=("${SHELL_CORE_PACKAGES[@]}")
    PACKAGES_TO_INSTALL+=("${SHELL_UTILITY_PACKAGES[@]}")
    
    # Interactive prompts
    prompt_shell_choice
    prompt_optional_alias_tools
    prompt_development_tools
    prompt_hyprland
    prompt_gaming
    
    # Show what will be installed
    show_pre_install_summary
    
    # Confirm before installing
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "  Ready to install ${#PACKAGES_TO_INSTALL[@]} packages?"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    read -r -p "Continue? (y/n): " confirm
    echo ""
    
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        warn "Installation cancelled"
        log "User cancelled installation"
        echo ""
        echo "To run installation again, execute: $0"
        exit 0
    fi
    
    # Install packages
    install_packages
    
    # Post-install setup
    post_install_setup
    
    # Show summary
    show_install_summary
    
    # Next steps
    echo ""
    echo "📋 NEXT STEPS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "1. Deploy dotfiles:"
    echo "   $ cd ~/dotfiles && ./setup.sh"
    echo ""
    
    if [[ "$INSTALL_ZSH" == "true" ]]; then
        echo "2. Switch to Zsh (optional):"
        echo "   $ ./switch-to-zsh.sh"
        echo "   $ exec zsh"
        echo ""
    fi
    
    echo "3. Read documentation:"
    echo "   $ cat home/README.md"
    echo "   $ cat docs/SHELL_GUIDE.md"
    echo ""

    if [[ "$INSTALL_GAMING" == "true" ]]; then
        echo "4. Finish gaming setup:"
        echo "   $ protonplus"
        echo "   # install the latest GE-Proton for Steam and Heroic"
        echo ""
    fi
    
    if [[ "$INSTALL_HYPRLAND" == "true" ]]; then
        if [[ "$INSTALL_GAMING" == "true" ]]; then
            echo "5. Start Hyprland:"
        else
            echo "4. Start Hyprland:"
        fi
        echo "   $ exec Hyprland"
        echo ""
    fi
    
    echo "📁 Full log saved to: $LOG_FILE"
    echo ""
    success "All done! Happy hacking! 🚀"
    echo ""
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
