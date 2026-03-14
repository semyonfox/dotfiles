#!/usr/bin/env bash
# Common functions for dotfiles installation scripts

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Global state
LOG_FILE=""
INSTALLED_PACKAGES=()
FAILED_OPTIONAL_PACKAGES=()

# ======================================================================
# BASIC OUTPUT FUNCTIONS
# ======================================================================

info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

# Log message (to file only, no stdout)
log() {
    [[ -n "$LOG_FILE" ]] && echo "$1" >> "$LOG_FILE"
}

# ======================================================================
# OS DETECTION
# ======================================================================

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif grep -qiE 'Microsoft|WSL' /proc/version 2>/dev/null; then
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            echo "wsl-$ID"
        else
            echo "wsl-unknown"
        fi
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

is_wsl() {
    grep -qiE 'Microsoft|WSL' /proc/version 2>/dev/null
}

get_base_os() {
    local os=$(detect_os)
    echo "${os#wsl-}"
}

# ======================================================================
# PACKAGE MANAGER DETECTION
# ======================================================================

detect_package_manager() {
    local base_os=$(get_base_os)
    
    case "$base_os" in
        arch|cachyos|endeavouros|manjaro)
            # Try paru first, then yay, then pacman
            if command -v paru &>/dev/null; then
                echo "paru"
            elif command -v yay &>/dev/null; then
                echo "yay"
            else
                echo "pacman"
            fi
            ;;
        ubuntu|debian|pop|linuxmint)
            echo "apt"
            ;;
        fedora|rhel|centos)
            echo "dnf"
            ;;
        macos)
            echo "brew"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

get_install_command() {
    local pkg_manager="$1"
    local base_os=$(get_base_os)
    
    case "$pkg_manager" in
        paru|yay)
            echo "$pkg_manager -S --needed --noconfirm"
            ;;
        pacman)
            echo "sudo pacman -S --needed --noconfirm"
            ;;
        apt)
            echo "sudo apt update && sudo apt install -y"
            ;;
        dnf)
            echo "sudo dnf install -y"
            ;;
        brew)
            echo "brew install"
            ;;
    esac
}

# ======================================================================
# LOGGING SETUP
# ======================================================================

setup_logging() {
    LOG_FILE="$HOME/.dotfiles-install-$(date +%Y%m%d_%H%M%S).log"
    
    # Create empty log file
    touch "$LOG_FILE" || error "Failed to create log file: $LOG_FILE"
    
    # Log header
    {
        echo "═══════════════════════════════════════════════════════════════"
        echo "Dotfiles Dependency Installation Log"
        echo "Started: $(date)"
        echo "═══════════════════════════════════════════════════════════════"
        echo ""
    } >> "$LOG_FILE"
    
    info "Logging to: $LOG_FILE"
}

# ======================================================================
# PACKAGE INSTALLATION
# ======================================================================

# Internal: install package (uses package manager)
_install_package_impl() {
    local package="$1"
    local pkg_manager="$2"
    local install_cmd="$3"
    
    local pkg_name=$(get_package_name "$package" 2>/dev/null || echo "$package")
    
    info "Installing: $package"
    
    # Run install command, capture output
    if $install_cmd "$pkg_name" >> "$LOG_FILE" 2>&1; then
        return 0
    else
        return 1
    fi
}

# Install CRITICAL package - exit on failure
install_package_critical() {
    local package="$1"
    local pkg_manager="$2"
    local install_cmd="$3"
    
    if _install_package_impl "$package" "$pkg_manager" "$install_cmd"; then
        success "Installed: $package"
        INSTALLED_PACKAGES+=("$package")
    else
        error "Failed to install critical package: $package"
        # Note: error() calls exit 1
    fi
}

# Install OPTIONAL package - continue on failure
install_package_optional() {
    local package="$1"
    local pkg_manager="$2"
    local install_cmd="$3"
    
    if _install_package_impl "$package" "$pkg_manager" "$install_cmd"; then
        success "Installed: $package"
        INSTALLED_PACKAGES+=("$package")
    else
        warn "Failed to install optional package: $package (continuing)"
        FAILED_OPTIONAL_PACKAGES+=("$package")
        return 1
    fi
}

# ======================================================================
# SUMMARY & REPORTING
# ======================================================================

show_install_summary() {
    local total_installed=${#INSTALLED_PACKAGES[@]}
    local total_failed=${#FAILED_OPTIONAL_PACKAGES[@]}
    
    {
        echo ""
        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║              INSTALLATION COMPLETE                         ║"
        echo "╚════════════════════════════════════════════════════════════╝"
        echo ""
        
        echo "✅ SUCCESSFULLY INSTALLED ($total_installed packages)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        for pkg in "${INSTALLED_PACKAGES[@]}"; do
            echo "  ✓ $pkg"
        done
        echo ""
        
        if [[ $total_failed -gt 0 ]]; then
            echo "⚠️  FAILED OPTIONAL PACKAGES ($total_failed - skipped)"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            for pkg in "${FAILED_OPTIONAL_PACKAGES[@]}"; do
                echo "  ✗ $pkg"
            done
            echo ""
            echo "  You can install these manually:"
            local install_cmd=$(get_install_command "$(detect_package_manager)")
            echo "  $ $install_cmd ${FAILED_OPTIONAL_PACKAGES[@]}"
            echo ""
        fi
        
        echo "📁 INSTALLATION LOG"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  Location: $LOG_FILE"
        echo ""
        
    } | tee -a "$LOG_FILE"
}

# ======================================================================
# HELPER FUNCTIONS
# ======================================================================

# Get package name for current OS
get_package_name() {
    local package="$1"
    local base_os=$(get_base_os)
    
    # Source package-lists.sh if available
    if [[ -f "$SCRIPT_DIR/lib/package-lists.sh" ]]; then
        # This will be sourced separately
        :
    fi
    
    # Return the package name (assumes sourced package-lists.sh)
    case "$base_os" in
        arch|cachyos|endeavouros|manjaro)
            echo "${PACKAGE_NAMES_ARCH[$package]:-$package}"
            ;;
        ubuntu|debian|pop|linuxmint)
            echo "${PACKAGE_NAMES_UBUNTU[$package]:-$package}"
            ;;
        fedora|rhel|centos)
            echo "${PACKAGE_NAMES_FEDORA[$package]:-$package}"
            ;;
        macos)
            echo "${PACKAGE_NAMES_MACOS[$package]:-$package}"
            ;;
        *)
            echo "$package"
            ;;
    esac
}

# Check if package is already installed
is_package_installed() {
    local package="$1"
    command -v "$package" &>/dev/null
}
