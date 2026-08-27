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

# Comprehensive system cleanup for Arch Linux
cleanup() {
    local before after freed step=0 total=17

    echo -e "\n\e[96m╭─────────────────────────────────────────────────╮\e[0m"
    echo -e "\e[96m│\e[0m  \e[1;97mSystem Cleanup\e[0m                              \e[96m│\e[0m"
    echo -e "\e[96m╰─────────────────────────────────────────────────╯\e[0m\n"

    before=$(df --output=used / | tail -1 | tr -d ' ')

    # ── System ───────────────────────────────────────────────────────────
    echo -e "\e[96m── System ──────────────────────────────────────────\e[0m"

    echo -e "\e[93m[$((++step))/$total]\e[0m Clearing pacman cache (keeping last 3)..."
    if command -v paccache &>/dev/null; then
        sudo paccache -rk3 2>/dev/null
    else
        sudo pacman -Sc --noconfirm
    fi

    echo -e "\e[93m[$((++step))/$total]\e[0m Removing orphaned packages..."
    if orphans=$(pacman -Qtdq 2>/dev/null); then
        echo "$orphans" | sudo pacman -Rns --noconfirm -
    else
        echo "      No orphaned packages found"
    fi

    echo -e "\e[93m[$((++step))/$total]\e[0m Clearing AUR helper cache..."
    if command -v paru &>/dev/null; then
        paru -Sc --noconfirm 2>/dev/null
    elif command -v yay &>/dev/null; then
        yay -Sc --noconfirm 2>/dev/null
    elif command -v pikaur &>/dev/null; then
        pikaur -Sc --noconfirm 2>/dev/null
    else
        echo "      No AUR helper found, skipping"
    fi

    echo -e "\e[93m[$((++step))/$total]\e[0m Removing unused Flatpak runtimes..."
    if command -v flatpak &>/dev/null; then
        flatpak uninstall --unused --noninteractive 2>/dev/null
    else
        echo "      flatpak not installed, skipping"
    fi

    echo -e "\e[93m[$((++step))/$total]\e[0m Pruning snapper snapshots (keeping last 3)..."
    if command -v snapper &>/dev/null; then
        for cfg in root home; do
            to_delete=$(snapper -c "$cfg" list --columns number 2>/dev/null \
                | tail -n +2 \
                | grep -Ev '^\s*$|^0$' \
                | sort -n \
                | head -n -3)
            if [[ -n "$to_delete" ]]; then
                echo "      $cfg: removing $(echo "$to_delete" | wc -l | tr -d ' ') snapshot(s)"
                echo "$to_delete" | xargs -r sudo snapper -c "$cfg" delete
            else
                echo "      $cfg: nothing to prune"
            fi
        done
    else
        echo "      snapper not installed, skipping"
    fi

    echo -e "\e[93m[$((++step))/$total]\e[0m Clearing systemd journal (keeping 3 days)..."
    sudo journalctl --vacuum-time=3d 2>/dev/null

    echo -e "\e[93m[$((++step))/$total]\e[0m Clearing temporary files..."
    sudo systemd-tmpfiles --clean 2>/dev/null

    echo -e "\e[93m[$((++step))/$total]\e[0m Clearing user cache..."
    rm -rf ~/.cache/* 2>/dev/null

    echo -e "\e[93m[$((++step))/$total]\e[0m Clearing thumbnails and trash..."
    rm -rf ~/.thumbnails/* ~/.local/share/Trash/* 2>/dev/null

    # ── Docker ───────────────────────────────────────────────────────────
    echo -e "\n\e[96m── Docker ──────────────────────────────────────────\e[0m"

    if command -v docker &>/dev/null; then
        echo -e "\e[93m[$((++step))/$total]\e[0m Removing stopped containers..."
        docker container prune -f 2>/dev/null

        echo -e "\e[93m[$((++step))/$total]\e[0m Removing unused images..."
        docker image prune -af 2>/dev/null

        echo -e "\e[93m[$((++step))/$total]\e[0m Removing unused volumes..."
        docker volume prune -f 2>/dev/null

        echo -e "\e[93m[$((++step))/$total]\e[0m Clearing build cache..."
        docker builder prune -af 2>/dev/null
    else
        step=$((step + 4))
        echo "      docker not installed, skipping"
    fi

    # ── Dev tools ────────────────────────────────────────────────────────
    echo -e "\n\e[96m── Dev tools ───────────────────────────────────────\e[0m"

    echo -e "\e[93m[$((++step))/$total]\e[0m Clearing npm cache..."
    if command -v npm &>/dev/null; then
        npm cache clean --force 2>/dev/null
    else
        echo "      npm not installed, skipping"
    fi

    echo -e "\e[93m[$((++step))/$total]\e[0m Pruning pnpm store..."
    if command -v pnpm &>/dev/null; then
        pnpm store prune 2>/dev/null
    else
        echo "      pnpm not installed, skipping"
    fi

    echo -e "\e[93m[$((++step))/$total]\e[0m Clearing uv cache..."
    if command -v uv &>/dev/null; then
        uv cache clean 2>/dev/null
    else
        echo "      uv not installed, skipping"
    fi

    echo -e "\e[93m[$((++step))/$total]\e[0m Clearing pip cache and Python user packages..."
    if command -v pip3 &>/dev/null; then
        pip3 cache purge 2>/dev/null
    fi
    rm -rf ~/.local/lib/python*/site-packages 2>/dev/null

    after=$(df --output=used / | tail -1 | tr -d ' ')
    freed=$((before - after))

    echo -e "\n\e[96m╭─────────────────────────────────────────────────╮\e[0m"
    echo -e "\e[96m│\e[0m  \e[92mCleanup Complete!\e[0m                           \e[96m│\e[0m"
    if [[ $freed -gt 0 ]]; then
        printf "\e[96m│\e[0m  \e[92mSpace freed: %-33s\e[96m│\e[0m\n" "$(numfmt --to=iec --suffix=B $((freed * 1024)))"
    else
        echo -e "\e[96m│\e[0m  \e[93mSpace freed: 0B (or negligible)\e[0m            \e[96m│\e[0m"
    fi
    echo -e "\e[96m╰─────────────────────────────────────────────────╯\e[0m\n"

    echo -e "\e[93mTop 10 largest directories:\e[0m\n"
    du -h --max-depth=1 ~/ 2>/dev/null | sort -rh | sed -n '2,11p' | nl -w2 -s'. '
    echo
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
    local claude_path codex_path npm_prefix opencode_path

    npm_prefix="$(npm prefix -g 2>/dev/null || printf '%s' "${NPM_CONFIG_PREFIX:-$HOME/.local}")"

    echo "==> system (paru)"
    paru -Syu --noconfirm --sudoloop --combinedupgrade --batchinstall || echo "!!paru failed"

    echo ""
    echo "==> Claude Code (native)"
    if command -v curl &>/dev/null; then
        if [[ -d "$npm_prefix/lib/node_modules/@anthropic-ai/claude-code" ]]; then
            npm uninstall -g @anthropic-ai/claude-code || echo "!! old Claude Code npm package cleanup failed"
        fi
        if [[ -L "$HOME/.local/bin/claude" ]] && [[ "$(readlink "$HOME/.local/bin/claude")" == "$npm_prefix/bin/claude" ]]; then
            unlink "$HOME/.local/bin/claude"
        fi

        claude_path="$(readlink -f "$HOME/.local/bin/claude" 2>/dev/null || true)"
        if [[ "$claude_path" == "$HOME/.local/share/claude/versions/"* ]] && [[ -x "$claude_path" ]]; then
            "$HOME/.local/bin/claude" update || echo "!! Claude Code native update failed"
        else
            curl -fsSL https://claude.ai/install.sh | bash -s latest || echo "!! Claude Code native install failed"
        fi

        claude_path="$(readlink -f "$HOME/.local/bin/claude" 2>/dev/null || true)"
        if [[ "$claude_path" != "$HOME/.local/share/claude/versions/"* ]] || ! "$HOME/.local/bin/claude" --version; then
            echo "!! Claude Code native installation is not healthy" >&2
        fi
    else
        echo "!! curl is required to install Claude Code" >&2
    fi

    echo ""
    echo "==> Codex CLI"
    codex_path="$(readlink -f "$(command -v codex 2>/dev/null)" 2>/dev/null || true)"
    if [[ -n "$codex_path" ]] && command -v pacman &>/dev/null && pacman -Qo "$codex_path" &>/dev/null; then
        codex --version || echo "!! package-managed Codex check failed"
    else
        npm install -g @openai/codex@latest || echo "!!Codex npm update failed"
        if [[ -x "$npm_prefix/lib/node_modules/@openai/codex/bin/codex.js" ]]; then
            ln -sf "$npm_prefix/lib/node_modules/@openai/codex/bin/codex.js" "$HOME/.local/bin/codex"
        fi
    fi

    echo ""
    echo "==> OpenCode (native)"
    if command -v curl &>/dev/null; then
        if [[ -d "$npm_prefix/lib/node_modules/opencode-ai" ]]; then
            npm uninstall -g opencode-ai || echo "!! old OpenCode npm package cleanup failed"
        fi

        opencode_path="$HOME/.opencode/bin/opencode"
        if [[ -x "$opencode_path" ]]; then
            "$opencode_path" upgrade --method curl || echo "!! OpenCode native update failed"
        else
            curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path || echo "!! OpenCode native install failed"
        fi

        if [[ -x "$opencode_path" ]]; then
            mkdir -p "$HOME/.local/bin"
            ln -sfn "$opencode_path" "$HOME/.local/bin/opencode"
            "$HOME/.local/bin/opencode" --version || echo "!! OpenCode native version check failed"
        else
            echo "!! OpenCode native installation is not healthy" >&2
        fi
    else
        echo "!! curl is required to install OpenCode" >&2
    fi
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
        pipx upgrade-all || echo "!!pipx failed"
    else
        echo "!!pipx unavailable (uv not installed)"
    fi

    echo ""
    echo "==> uv tools"
    uv self update 2>/dev/null || true
    uv tool upgrade --all || echo "!!uv failed"
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
