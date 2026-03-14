#!/usr/bin/env bash
# Package definitions for dotfiles installation
# Organized by category and platform

# ======================================================================
# PACKAGE DESCRIPTIONS
# ======================================================================
declare -A PACKAGE_DESCRIPTIONS=(
    # Critical
    [stow]="Symlink manager - REQUIRED for dotfile deployment"
    [git]="Version control - REQUIRED for all workflows"

    # Shell - Core
    [zsh]="Modern shell with advanced features (Oh My Zsh support)"
    [bash]="POSIX shell (fallback, usually pre-installed)"
    [tmux]="Terminal multiplexer - aliases: t, ta, tat, tns, tls, tks"
    [neovim]="Modern editor - aliases: v, vi, vim"
    [curl]="Data transfer tool (typically pre-installed)"
    [wget]="File downloader (typically pre-installed)"

    # Shell - Utilities (core tools)
    [eza]="Modern ls replacement - aliases: ls, ll, la, l, lt, tree"
    [bat]="Syntax-highlighted cat - alias: cat"
    [fd]="Fast file finder - used by f() function"
    [ripgrep]="Fast grep - used by ftext() function"
    [fzf]="Fuzzy finder - Ctrl+R history, Ctrl+T file picker"
    [zoxide]="Smart cd - alias: cdi"
    [starship]="Modern prompt theme with git integration"

    # Shell - Optional alias tools
    [lazygit]="Git terminal UI - alias: lg"
    [dooit]="Terminal todo manager - alias: todo"
    [pomodoro-tui]="Terminal timer - alias: pomodoro"
    [thefuck]="Command corrector - alias: fuck"

    # Desktop - Hyprland
    [hyprland]="Wayland window manager"
    [hyprland-protocols]="Hyprland protocol libraries"
    [xwayland]="X11 server on Wayland (compatibility)"
    [rofi-wayland]="Application launcher for Wayland"
    [swww]="Wallpaper daemon for Wayland"

    # Desktop - Waybar
    [waybar]="Status bar/taskbar for Wayland"

    # Desktop - Notifications
    [sway-notification-center]="Notification daemon for Wayland (swaynotificationcenter)"

    # Development - Optional
    [nvm]="Node version manager"
    [pyenv]="Python version manager"
    [rustup]="Rust toolchain installer"
)

# ======================================================================
# ARCH LINUX - Package names
# ======================================================================
declare -A PACKAGE_NAMES_ARCH=(
    [stow]="stow"
    [git]="git"
    [zsh]="zsh"
    [bash]="bash"
    [tmux]="tmux"
    [neovim]="neovim"
    [curl]="curl"
    [wget]="wget"
    [eza]="eza"
    [bat]="bat"
    [fd]="fd"
    [ripgrep]="ripgrep"
    [fzf]="fzf"
    [zoxide]="zoxide"
    [starship]="starship"
    [lazygit]="lazygit"
    [dooit]="dooit"
    [pomodoro-tui]="pomodoro-tui"
    [thefuck]="thefuck"
    [hyprland]="hyprland"
    [hyprland-protocols]="hyprland-protocols"
    [xwayland]="xwayland"
    [rofi-wayland]="rofi-wayland"
    [swww]="swww"
    [waybar]="waybar"
    [sway-notification-center]="sway-notification-center"
    [nvm]="nvm"
    [pyenv]="pyenv"
    [rustup]="rustup"
)

# ======================================================================
# UBUNTU/DEBIAN - Package names
# ======================================================================
declare -A PACKAGE_NAMES_UBUNTU=(
    [stow]="stow"
    [git]="git"
    [zsh]="zsh"
    [bash]="bash"
    [tmux]="tmux"
    [neovim]="neovim"
    [curl]="curl"
    [wget]="wget"
    [eza]="eza"
    [bat]="bat"           # newer Ubuntu, else batcat
    [fd]="fd-find"
    [ripgrep]="ripgrep"
    [fzf]="fzf"
    [zoxide]="zoxide"     # from script usually
    [starship]="starship" # from script usually
    [lazygit]="lazygit"
    [dooit]="dooit"
    [pomodoro-tui]="pomodoro-tui"
    [thefuck]="thefuck"
    [hyprland]="hyprland"
    [hyprland-protocols]="hyprland-protocols"
    [xwayland]="xwayland"
    [rofi-wayland]="rofi-wayland"
    [swww]="swww"
    [waybar]="waybar"
    [sway-notification-center]="sway-notification-center"
    [nvm]="nvm"           # from script
    [pyenv]="pyenv"       # from script
    [rustup]="rustup"     # from script
)

# ======================================================================
# FEDORA - Package names
# ======================================================================
declare -A PACKAGE_NAMES_FEDORA=(
    [stow]="stow"
    [git]="git"
    [zsh]="zsh"
    [bash]="bash"
    [tmux]="tmux"
    [neovim]="neovim"
    [curl]="curl"
    [wget]="wget"
    [eza]="eza"
    [bat]="bat"
    [fd]="fd"
    [ripgrep]="ripgrep"
    [fzf]="fzf"
    [zoxide]="zoxide"
    [starship]="starship"
    [lazygit]="lazygit"
    [dooit]="dooit"
    [pomodoro-tui]="pomodoro-tui"
    [thefuck]="thefuck"
    [hyprland]="hyprland"
    [hyprland-protocols]="hyprland-protocols"
    [xwayland]="xwayland"
    [rofi-wayland]="rofi-wayland"
    [swww]="swww"
    [waybar]="waybar"
    [sway-notification-center]="sway-notification-center"
    [nvm]="nvm"
    [pyenv]="pyenv"
    [rustup]="rustup"
)

# ======================================================================
# MACOS - Package names (via Homebrew)
# ======================================================================
declare -A PACKAGE_NAMES_MACOS=(
    [stow]="stow"
    [git]="git"
    [zsh]="zsh"
    [bash]="bash"
    [tmux]="tmux"
    [neovim]="neovim"
    [curl]="curl"
    [wget]="wget"
    [eza]="eza"
    [bat]="bat"
    [fd]="fd"
    [ripgrep]="ripgrep"
    [fzf]="fzf"
    [zoxide]="zoxide"
    [starship]="starship"
    [lazygit]="lazygit"
    [dooit]="dooit"
    [pomodoro-tui]="pomodoro-tui"
    [thefuck]="thefuck"
    # No Hyprland/Waybar on macOS
    [nvm]="nvm"
    [pyenv]="pyenv"
    [rustup]="rustup"
)

# ======================================================================
# PACKAGE CATEGORIES - Installation order
# ======================================================================

# Critical packages - must succeed or exit
CRITICAL_PACKAGES=(
    "stow"
    "git"
)

# Shell core packages - must succeed or exit
SHELL_CORE_PACKAGES=(
    "tmux"
    "neovim"
)

# Shell utilities - must succeed or exit (required for aliases to work)
SHELL_UTILITY_PACKAGES=(
    "eza"
    "bat"
    "fd"
    "ripgrep"
    "fzf"
    "zoxide"
    "starship"
)

# Shell optional - user choice, non-critical
SHELL_OPTIONAL_PACKAGES=(
    "lazygit"
    "dooit"
    "pomodoro-tui"
    "thefuck"
)

# Desktop - Hyprland and related (Linux with GUI only)
HYPRLAND_PACKAGES=(
    "hyprland"
    "hyprland-protocols"
    "xwayland"
    "rofi-wayland"
    "swww"
)

# Desktop - Waybar (Linux with GUI only)
WAYBAR_PACKAGES=(
    "waybar"
)

# Desktop - Notifications (Linux with GUI only)
SWAYNC_PACKAGES=(
    "sway-notification-center"
)

# Development - Optional user choice
DEVELOPMENT_PACKAGES=(
    "nvm"
    "pyenv"
    "rustup"
)

# ======================================================================
# HELPER FUNCTIONS
# ======================================================================

# Get package name for current OS
get_package_name() {
    local package="$1"
    local base_os=$(get_base_os)
    
    case "$base_os" in
        arch|cachyos|endeavouros|manjaro)
            echo "${PACKAGE_NAMES_ARCH[$package]}"
            ;;
        ubuntu|debian|pop|linuxmint)
            echo "${PACKAGE_NAMES_UBUNTU[$package]}"
            ;;
        fedora|rhel|centos)
            echo "${PACKAGE_NAMES_FEDORA[$package]}"
            ;;
        macos)
            echo "${PACKAGE_NAMES_MACOS[$package]}"
            ;;
        *)
            echo "$package"
            ;;
    esac
}

# Get package description
get_package_description() {
    local package="$1"
    echo "${PACKAGE_DESCRIPTIONS[$package]:-$package}"
}

# Build formatted package list for display
format_package_list() {
    local category="$1"
    shift
    local packages=("$@")
    
    echo ""
    echo "[$category]"
    for pkg in "${packages[@]}"; do
        printf "  • %-20s %s\n" "$pkg" "$(get_package_description "$pkg")"
    done
}

# Count packages in array
count_packages() {
    local array=("$@")
    echo "${#array[@]}"
}

# Print all packages (with descriptions) for viewing
print_all_packages() {
    {
        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║              PACKAGES TO BE INSTALLED                       ║"
        echo "╚════════════════════════════════════════════════════════════╝"
        echo ""
        
        echo "⭐ CRITICAL (Required)"
        format_package_list "CRITICAL" "${CRITICAL_PACKAGES[@]}"
        
        echo ""
        echo "🔧 SHELL - CORE (Required)"
        format_package_list "SHELL CORE" "${SHELL_CORE_PACKAGES[@]}"
        
        echo ""
        echo "🛠️  SHELL - UTILITIES (Required for aliases)"
        format_package_list "SHELL UTILITIES" "${SHELL_UTILITY_PACKAGES[@]}"
        
        if [[ ${#SHELL_OPTIONAL_PACKAGES[@]} -gt 0 ]]; then
            echo ""
            echo "✨ SHELL - OPTIONAL (User choice)"
            format_package_list "SHELL OPTIONAL" "${SHELL_OPTIONAL_PACKAGES[@]}"
        fi
        
        if [[ ${#HYPRLAND_PACKAGES[@]} -gt 0 ]]; then
            echo ""
            echo "🖥️  DESKTOP - HYPRLAND (Linux GUI only)"
            format_package_list "HYPRLAND" "${HYPRLAND_PACKAGES[@]}"
            
            echo ""
            echo "📊 DESKTOP - WAYBAR (Linux GUI only)"
            format_package_list "WAYBAR" "${WAYBAR_PACKAGES[@]}"
            
            echo ""
            echo "🔔 DESKTOP - NOTIFICATIONS (Linux GUI only)"
            format_package_list "SWAYNC" "${SWAYNC_PACKAGES[@]}"
        fi
        
        if [[ ${#DEVELOPMENT_PACKAGES[@]} -gt 0 ]]; then
            echo ""
            echo "💻 DEVELOPMENT (Optional)"
            format_package_list "DEVELOPMENT" "${DEVELOPMENT_PACKAGES[@]}"
        fi
        
        echo ""
        echo "╔════════════════════════════════════════════════════════════╗"
        local total=$((${#CRITICAL_PACKAGES[@]} + ${#SHELL_CORE_PACKAGES[@]} + ${#SHELL_UTILITY_PACKAGES[@]} + ${#SHELL_OPTIONAL_PACKAGES[@]} + ${#HYPRLAND_PACKAGES[@]} + ${#WAYBAR_PACKAGES[@]} + ${#SWAYNC_PACKAGES[@]} + ${#DEVELOPMENT_PACKAGES[@]}))
        echo "║  Total: $total packages                                              ║"
        echo "╚════════════════════════════════════════════════════════════╝"
        echo ""
        
    } | less -R
}
