# ======================================================================
# FUNCTIONS - FILE OPERATIONS
# ======================================================================
# Create directory and enter it
mkcd() {
    [[ $# -eq 0 ]] && { echo "Usage: mkcd <directory>"; return 1; }
    mkdir -p "$1" && cd "$1"
}

# Create backup of file
backup() {
    [[ $# -eq 0 ]] && { echo "Usage: backup <file>"; return 1; }
    cp "$1"{,.bak} && echo "Backed up: $1 -> $1.bak"
}

# Find files by name
f() {
    [[ $# -eq 0 ]] && { echo "Usage: f <pattern>"; return 1; }
    find . -name "*$1*" 2>/dev/null
}

# Search text in files
ftext() {
    [[ $# -eq 0 ]] && { echo "Usage: ftext <pattern>"; return 1; }
    grep -rnw . -e "$1" 2>/dev/null
}

# Extract various archive formats
extract() {
    [[ $# -eq 0 ]] && { echo "Usage: extract <archive>"; return 1; }
    [[ ! -f "$1" ]] && { echo "Error: '$1' not found"; return 1; }

    case "$1" in
        *.tar.bz2)  tar xjf "$1" ;;
        *.tar.gz)   tar xzf "$1" ;;
        *.tar.xz)   tar xf "$1" ;;
        *.tar.zst)  tar xf "$1" ;;
        *.tar)      tar xf "$1" ;;
        *.tgz)      tar xzf "$1" ;;
        *.bz2)      bunzip2 "$1" ;;
        *.gz)       gunzip "$1" ;;
        *.rar)      unrar x "$1" ;;
        *.zip)      unzip "$1" ;;
        *.7z)       7z x "$1" ;;
        *.deb)      ar x "$1" ;;
        *)          echo "Error: Unsupported format '$1'" ;;
    esac
}

# ====================================================================== 
# FUNCTIONS - SSH
# ====================================================================== 

# Quick SSH connections
sssh() {
    case "$1" in
        server) ssh server ;;
        nas)     ssh nas ;;
        pc)      ssh pc ;;
        laptop)  ssh laptop ;;
        "" )      echo "Usage: sssh <server|hostname>"; return 1 ;; 
        *)       ssh "$1" ;;
    esac
}

# Completion for sssh
_sssh_complete() {
    local hosts custom_hosts
    custom_hosts="server nas pc laptop"
    hosts=$(grep "^Host" ~/.ssh/config 2>/dev/null | grep -v "[?*]" | awk '{print $2}')
    COMPREPLY=($(compgen -W "$hosts $custom_hosts" -- "${COMP_WORDS[COMP_CWORD]}"))
}
complete -F _sssh_complete sssh

# ====================================================================== 
# FUNCTIONS - SYSTEM MAINTENANCE
# ====================================================================== 

# prune rebuildable package caches without touching installed tools or Docker data
cleanup() {
    if [[ $# -gt 1 ]]; then
        printf 'Usage: cleanup [--dry-run|--deep|--help]\n' >&2
        return 2
    fi
    case "${1:-}" in
        --help|-h)
            printf 'Usage: cleanup [--dry-run|--deep|--help]\n'
            printf 'Default: prune package caches. --deep also clears idle Gradle, Playwright and npx caches.\n'
            return 0
            ;;
        --dry-run|--deep|"") ;;
        *)
            printf 'Usage: cleanup [--dry-run|--deep|--help]\n' >&2
            return 2
            ;;
    esac

    printf 'Cache sizes before cleanup:\n'
    du -sh "$HOME/.cache/uv" "$HOME/.npm/_cacache" "$HOME/.cache/pnpm" \
        "$HOME/.cache/pip" "$HOME/.gradle/caches" \
        "$HOME/.cache/ms-playwright" "$HOME/.npm/_npx" 2>/dev/null || true
    [[ ${1:-} == --dry-run ]] && return 0

    local failed=0
    if command -v uv >/dev/null 2>&1; then
        if ! command -v pgrep >/dev/null 2>&1; then
            printf '\nSkipping uv cache: cannot check for active uv processes\n'
        elif pgrep -u "$(id -u)" -x uv >/dev/null 2>&1; then
            printf '\nSkipping uv cache: uv is running\n'
        else
            printf '\nPruning uv cache...\n'
            uv cache prune || failed=1
        fi
    fi
    if command -v npm >/dev/null 2>&1; then
        printf '\nClearing npm download cache...\n'
        npm cache clean --force || failed=1
    fi
    if command -v pnpm >/dev/null 2>&1; then
        printf '\nPruning pnpm store...\n'
        pnpm store prune || failed=1
    fi
    if command -v pip3 >/dev/null 2>&1; then
        printf '\nClearing pip download cache...\n'
        pip3 cache purge || failed=1
    fi

    if [[ ${1:-} == --deep ]]; then
        if ! command -v pgrep >/dev/null 2>&1; then
            printf '\nSkipping large caches: cannot check active processes\n'
        else
            local user_id
            user_id=$(id -u)
            if pgrep -u "$user_id" -f 'GradleDaemon|gradle-launcher' >/dev/null 2>&1; then
                printf '\nSkipping Gradle cache: Gradle is running\n'
            else
                printf '\nClearing Gradle build cache...\n'
                rm -rf -- "$HOME/.gradle/caches" || failed=1
            fi
            if pgrep -u "$user_id" -f 'ms-playwright|playwright|chromium|firefox|webkit' >/dev/null 2>&1; then
                printf '\nSkipping Playwright browsers: a browser or test is running\n'
            else
                printf '\nClearing Playwright browser downloads...\n'
                rm -rf -- "$HOME/.cache/ms-playwright" || failed=1
            fi
            if pgrep -u "$user_id" -f "$HOME/.npm/_npx" >/dev/null 2>&1; then
                printf '\nSkipping npx cache: a cached tool is running\n'
            else
                printf '\nClearing npx cache...\n'
                rm -rf -- "$HOME/.npm/_npx" || failed=1
            fi
        fi
    fi

    printf '\nRoot filesystem free: '
    df -h / | awk 'NR == 2 {print $4}'
    return "$failed"
}

# ====================================================================== 
# FUNCTIONS - WELCOME MESSAGE
# ====================================================================== 

_welcome_bar() {
    # time-based greeting (matches zsh version)
    local greeting="Welcome back"
    local hour=$(date +%H)

    if [[ $hour -ge 5 && $hour -lt 12 ]]; then
        greeting="Good morning"
    elif [[ $hour -ge 12 && $hour -lt 17 ]]; then
        greeting="Good afternoon"
    elif [[ $hour -ge 17 && $hour -lt 22 ]]; then
        greeting="Good evening"
    else
        greeting="Burning the midnight oil"
    fi

    # Get CPU load (1-minute average)
    local cpu_load
    cpu_load=$(cut -d " " -f1 /proc/loadavg)

    # Calculate CPU percentage
    local cpu_cores
    cpu_cores=$(nproc)
    local cpu_pct
    cpu_pct=$(awk -v loadavg="$cpu_load" -v cores="$cpu_cores" 'BEGIN {printf "%.0f", (loadavg/cores)*100}')
    [[ $cpu_pct -gt 100 ]] && cpu_pct=100

    # Get memory usage
    local mem_total mem_available mem_used mem_pct
    mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    mem_used=$((mem_total - mem_available))
    mem_pct=$((mem_used * 100 / mem_total))

    # Get root filesystem usage
    local disk_pct
    disk_pct=$(df -P / | awk 'NR == 2 {gsub("%", "", $5); print $5}')

    _welcome_meter() {
        local pct=$1 color=$2 index
        local filled=$(((pct * 8 + 50) / 100))
        printf '\e[%sm' "$color"
        for ((index = 0; index < filled; index++)); do printf '█'; done
        printf '\e[0;2m'
        for ((index = filled; index < 8; index++)); do printf '░'; done
        printf '\e[0m'
    }

    _welcome_color() {
        if [[ $1 -gt 85 ]]; then
            printf '31'
        elif [[ $1 -ge 60 ]]; then
            printf '33'
        else
            printf '32'
        fi
    }

    # Display welcome message
    local label="$greeting, $USER"
    local cpu_color ram_color disk_color cpu_meter ram_meter disk_meter
    cpu_color=$(_welcome_color "$cpu_pct")
    ram_color=$(_welcome_color "$mem_pct")
    disk_color=$(_welcome_color "$disk_pct")
    cpu_meter=$(_welcome_meter "$cpu_pct" "$cpu_color")
    ram_meter=$(_welcome_meter "$mem_pct" "$ram_color")
    disk_meter=$(_welcome_meter "$disk_pct" "$disk_color")
    unset -f _welcome_meter _welcome_color
    echo
    echo -e "\e[96m╭─────────────────────────────────────╮\e[0m"
    printf "\e[96m│\e[0m  \e[1;97m%-33s\e[0m  \e[96m│\e[0m\n" "$label"
    echo -e "\e[96m├─────────────────────────────────────┤\e[0m"
    printf "\e[96m│\e[0m  \e[2mCPU\e[0m  [%s] \e[%sm%3s%%\e[0m               \e[96m│\e[0m\n" "$cpu_meter" "$cpu_color" "$cpu_pct"
    printf "\e[96m│\e[0m  \e[2mRAM\e[0m  [%s] \e[%sm%3s%%\e[0m               \e[96m│\e[0m\n" "$ram_meter" "$ram_color" "$mem_pct"
    printf "\e[96m│\e[0m  \e[2mDSK\e[0m  [%s] \e[%sm%3s%%\e[0m               \e[96m│\e[0m\n" "$disk_meter" "$disk_color" "$disk_pct"
    echo -e "\e[96m╰─────────────────────────────────────╯\e[0m"
    echo
}

# ======================================================================
# FUNCTIONS - GUI APPLICATIONS
# ======================================================================

gaming-check() {
    local packages=(
        steam
        heroic-games-launcher-bin
        protonplus
        umu-launcher
        gamescope
        mangohud
        gamemode
        lib32-gamemode
    )

    if ! command -v pacman &>/dev/null; then
        echo "pacman not available"
        return 0
    fi

    echo "gaming stack"
    for pkg in "${packages[@]}"; do
        if pacman -Q "$pkg" &>/dev/null; then
            pacman -Q "$pkg"
        else
            echo "$pkg not installed"
        fi
    done

    echo ""
    if command -v vulkaninfo &>/dev/null; then
        vulkaninfo --summary | rg 'deviceName|driverName' || vulkaninfo --summary
    else
        echo "vulkaninfo not installed"
    fi
}

update() {
    local ai_update_failed=0

    echo "==> system (paru)"
    paru -Syu --noconfirm --sudoloop --combinedupgrade --batchinstall || echo "!!paru failed"

    # Both shells use the same installation-aware provider updater.
    "$HOME/.local/bin/update-ai-clis" || ai_update_failed=1
    hash -r

    echo ""
    echo "==> flatpak"
    flatpak update -y || echo "!!flatpak failed"

    echo ""
    echo "==> rustup"
    rustup update || echo "!!rustup failed"

    echo ""
    echo "==> pnpm"
    pnpm self-update || echo "!!pnpm self-update failed"
    pnpm update -g || echo "!!pnpm failed"

    echo ""
    echo "==> pipx"
    if ! command -v pipx &>/dev/null && command -v uv &>/dev/null; then
        uv tool install pipx || echo "!!pipx install failed"
        hash -r
    fi
    if command -v pipx &>/dev/null; then
        "$HOME/.local/bin/update-pipx-venvs" || echo "!!pipx failed"
    else
        echo "!!pipx unavailable (uv not installed)"
    fi

    echo ""
    echo "==> uv tools"
    uv self update 2>/dev/null || true
    uv tool upgrade --all || echo "!!uv failed"
    return "$ai_update_failed"
}

gaming-modes() {
    cat <<'EOF'
normal
  launch directly from Steam or Heroic with no wrapper

gamescope mode
  gamescope -f -- %command%
  use when a game has fullscreen or focus issues

performance mode
  gamemoderun mangohud %command%
  use when you want FPS and frametime stats or extra scheduling help

battery-friendly mode
  MANGOHUD_CONFIG=fps_limit=40,no_display mangohud %command%
  use for lighter games on the Iris Xe iGPU
EOF
}
