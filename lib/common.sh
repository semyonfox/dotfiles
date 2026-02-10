#!/usr/bin/env bash
# Common functions for dotfiles installation scripts

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Helper functions
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Detect OS
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

# Check if running in WSL
is_wsl() {
    grep -qiE 'Microsoft|WSL' /proc/version 2>/dev/null
}

# Get base OS (strip wsl- prefix)
get_base_os() {
    local os=$(detect_os)
    echo "${os#wsl-}"
}
