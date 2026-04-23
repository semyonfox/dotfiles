# Linux Gaming Ready Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make this CachyOS Hyprland laptop gaming-ready for Steam and Heroic with a Proton-first workflow, current gaming packages, and optional manual gaming modes.

**Architecture:** Keep the runtime stack simple: Steam for Steam titles, Heroic for Epic titles, Proton-first everywhere, and raw Wine only as a fallback. Persist the setup in dotfiles where it makes sense by teaching the installer about gaming packages, adding shell helpers, and wiring the existing Hyprland gaming keybind to a real manual toggle script.

**Tech Stack:** Bash, Zsh, GNU Stow, pacman, Hyprland, Steam, Heroic, ProtonPlus, UMU, Gamescope, MangoHud, GameMode

---

### Task 1: Add gaming packages to the dotfiles installer

**Files:**

- Modify: `lib/package-lists.sh`
- Modify: `install-deps.sh`
- Test: `install-deps.sh` dry-run prompt flow via scripted stdin

- [ ] **Step 1: Add gaming package descriptions and Arch package mappings**

```bash
# add these entries to PACKAGE_DESCRIPTIONS in lib/package-lists.sh
[steam]="Valve's digital software delivery system"
[heroic-games-launcher-bin]="Epic and GOG launcher with Proton and Wine runners"
[protonplus]="Compatibility tools manager for Proton-GE and Wine-GE"
[umu-launcher]="Run Proton outside Steam for Heroic and other launchers"
[gamescope]="Micro-compositor for fullscreen games and scaling"
[mangohud]="Performance overlay and frame limiter"
[gamemode]="Feral GameMode daemon and client"
[lib32-gamemode]="32-bit GameMode client libraries"
[lutris]="Universal game launcher for Wine, launchers, and emulators"

# add these entries to PACKAGE_NAMES_ARCH in lib/package-lists.sh
[steam]="steam"
[heroic-games-launcher-bin]="heroic-games-launcher-bin"
[protonplus]="protonplus"
[umu-launcher]="umu-launcher"
[gamescope]="gamescope"
[mangohud]="mangohud"
[gamemode]="gamemode"
[lib32-gamemode]="lib32-gamemode"
[lutris]="lutris"
```

- [ ] **Step 2: Add dedicated gaming package groups**

```bash
# add these arrays near the other package category arrays in lib/package-lists.sh
GAMING_PACKAGES=(
    "steam"
    "heroic-games-launcher-bin"
    "protonplus"
    "umu-launcher"
    "gamescope"
    "mangohud"
    "gamemode"
    "lib32-gamemode"
)

GAMING_OPTIONAL_PACKAGES=(
    "lutris"
)
```

- [ ] **Step 3: Add a Proton-first gaming prompt to `install-deps.sh`**

```bash
# add these config flags near the other INSTALL_* variables in install-deps.sh
INSTALL_GAMING="false"
INSTALL_LUTRIS="false"

# add this function after prompt_hyprland()
prompt_gaming() {
    if is_wsl || [[ "$OSTYPE" == "darwin"* ]]; then
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
    read -p "Install Linux gaming stack? (y/n): " -n 1 choice
    echo ""

    if [[ $choice =~ ^[Yy]$ ]]; then
        PACKAGES_TO_INSTALL+=("${GAMING_PACKAGES[@]}")
        INSTALL_GAMING="true"
        info "Will install: Steam + Heroic Proton-first gaming stack"

        echo ""
        read -p "Also install Lutris for edge-case launchers? (y/n): " -n 1 lutris_choice
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
```

- [ ] **Step 4: Show gaming packages in the install summary and next steps**

```bash
# add these blocks to show_pre_install_summary() in install-deps.sh
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

# add this call in main() after prompt_hyprland
prompt_gaming

# add this next-steps block near the bottom of install-deps.sh
if [[ "$INSTALL_GAMING" == "true" ]]; then
    echo "4. Finish gaming setup:"
    echo "   $ protonplus"
    echo "   # install the latest GE-Proton for Steam and Heroic"
    echo ""
fi
```

- [ ] **Step 5: Update the package catalog display to include gaming groups**

```bash
# add these blocks to print_all_packages() in lib/package-lists.sh
if [[ ${#GAMING_PACKAGES[@]} -gt 0 ]]; then
    echo ""
    echo "🎮 GAMING - CORE (Optional)"
    format_package_list "GAMING CORE" "${GAMING_PACKAGES[@]}"
fi

if [[ ${#GAMING_OPTIONAL_PACKAGES[@]} -gt 0 ]]; then
    echo ""
    echo "🕹️  GAMING - OPTIONAL"
    format_package_list "GAMING OPTIONAL" "${GAMING_OPTIONAL_PACKAGES[@]}"
fi

# update the total calculation in print_all_packages()
local total=$((${#CRITICAL_PACKAGES[@]} + ${#SHELL_CORE_PACKAGES[@]} + ${#SHELL_UTILITY_PACKAGES[@]} + ${#SHELL_OPTIONAL_PACKAGES[@]} + ${#HYPRLAND_PACKAGES[@]} + ${#WAYBAR_PACKAGES[@]} + ${#SWAYNC_PACKAGES[@]} + ${#DEVELOPMENT_PACKAGES[@]} + ${#GAMING_PACKAGES[@]} + ${#GAMING_OPTIONAL_PACKAGES[@]}))
```

- [ ] **Step 6: Verify the installer flow and shell syntax**

Run:

```bash
bash -n install-deps.sh lib/package-lists.sh
printf '1\nn\nn\nn\ny\nn\nn\n' | ./install-deps.sh
```

Expected:

- `bash -n` exits successfully with no output
- the interactive run prints the new `🎮 LINUX GAMING` prompt
- the summary includes a `[GAMING - CORE]` section
- the script exits cleanly after the final `Continue?` prompt is answered with `n`

- [ ] **Step 7: Commit the installer changes**

```bash
git add lib/package-lists.sh install-deps.sh
git commit -m "feat(installer): add gaming package prompt"
```

### Task 2: Add shell helpers for gaming checks and mode suggestions

**Files:**

- Modify: `home/.bash_aliases`
- Modify: `home/.zsh_aliases`
- Modify: `home/.bash_functions`
- Modify: `home/.zsh_functions`
- Modify: `home/README.md`

- [ ] **Step 1: Add lightweight aliases for gaming commands in both shells**

```bash
# add these lines to both home/.bash_aliases and home/.zsh_aliases
alias gcheck='gaming-check'
alias gmodes='gaming-modes'
alias pplus='protonplus'
```

- [ ] **Step 2: Add `gaming-check()` to both shell function files**

```bash
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
```

- [ ] **Step 3: Add `gaming-modes()` to both shell function files**

```bash
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
  mangohud fps_limit=40,no_display %command%
  use for lighter games on the Iris Xe iGPU
EOF
}
```

- [ ] **Step 4: Document the new shell helpers**

```markdown
Add this subsection to home/README.md under the utility functions section:

#### Gaming Helpers

- `gcheck` - show installed gaming packages and the Vulkan driver summary
- `gmodes` - print suggested Steam and Heroic launch modes
- `pplus` - open ProtonPlus to manage GE-Proton and Wine-GE
```

- [ ] **Step 5: Verify both shell files load and the helpers run**

Run:

```bash
bash -n home/.bash_aliases home/.bash_functions
zsh -n home/.zsh_aliases home/.zsh_functions
bash -lc 'source home/.bash_aliases; source home/.bash_functions; gaming-modes | rg "performance mode"'
bash -lc 'source home/.bash_functions; gaming-check | rg "heroic-games-launcher-bin|deviceName"'
```

Expected:

- both shell syntax checks exit successfully
- `gaming-modes` prints the four mode presets
- `gaming-check` prints package status and the Vulkan device name

- [ ] **Step 6: Commit the shell helper changes**

```bash
git add home/.bash_aliases home/.zsh_aliases home/.bash_functions home/.zsh_functions home/README.md
git commit -m "feat(home): add gaming helper commands"
```

### Task 3: Implement the optional Hyprland gaming-mode toggle behind the existing keybind

**Files:**

- Create: `hyprland/.local/share/bin/gamemode.sh`
- Modify: `hyprland/README.md`
- Test: Hyprland runtime check using `hyprctl getoption`

- [ ] **Step 1: Create the `gamemode.sh` toggle script**

```bash
#!/usr/bin/env bash

set -e

STATE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/hypr-gaming-mode"

notify() {
    if command -v notify-send &>/dev/null; then
        notify-send "gaming mode" "$1"
    fi
}

if [[ -f "$STATE_FILE" ]]; then
    hyprctl keyword decoration:blur:enabled true
    hyprctl keyword animations:enabled true
    hyprctl keyword general:gaps_out 8
    rm -f "$STATE_FILE"
    notify "restored blur, animations, and normal gaps"
else
    mkdir -p "$(dirname "$STATE_FILE")"
    hyprctl keyword decoration:blur:enabled false
    hyprctl keyword animations:enabled false
    hyprctl keyword general:gaps_out 2
    touch "$STATE_FILE"
    notify "disabled blur and animations for games"
fi
```

- [ ] **Step 2: Make the script executable and rely on the existing keybind**

Run:

```bash
chmod +x hyprland/.local/share/bin/gamemode.sh
rg "gamemode.sh" hyprland/.config/hypr/keybindings.conf
```

Expected:

- the file is executable
- the existing keybind `bind = $mainMod+Alt, G, exec, $scrPath/gamemode.sh` is still present, so no keybinding edit is needed

- [ ] **Step 3: Document the manual gaming-mode toggle**

```markdown
Add this bullet to the quick keybindings section in hyprland/README.md:

- `SUPER + ALT + G` - toggle a lightweight gaming mode that disables blur and animations until toggled off
```

- [ ] **Step 4: Verify the toggle works from the current Hyprland session**

Run:

```bash
bash -n hyprland/.local/share/bin/gamemode.sh
./hyprland/.local/share/bin/gamemode.sh
hyprctl getoption decoration:blur:enabled
hyprctl getoption animations:enabled
./hyprland/.local/share/bin/gamemode.sh
hyprctl getoption decoration:blur:enabled
hyprctl getoption animations:enabled
```

Expected:

- syntax check passes with no output
- first run disables blur and animations
- second run restores blur and animations

- [ ] **Step 5: Commit the Hyprland gaming toggle**

```bash
git add hyprland/.local/share/bin/gamemode.sh hyprland/README.md
git commit -m "feat(hyprland): add manual gaming mode toggle"
```

### Task 4: Apply the gaming setup on the current machine and verify Steam and Heroic

**Files:**

- Use: system package manager and GUI launchers

- [ ] **Step 1: Install or refresh the gaming packages on the live system**

Run:

```bash
sudo pacman -S --needed steam heroic-games-launcher-bin protonplus umu-launcher gamescope mangohud gamemode lib32-gamemode
```

Expected:

- pacman reports all packages as installed or upgrades the ones that are behind
- no package removal happens in this step

- [ ] **Step 2: Install the latest GE-Proton with ProtonPlus**

Run:

```bash
protonplus
```

Expected:

- ProtonPlus opens
- install the latest `GE-Proton` for Steam

- [ ] **Step 3: Set the Steam defaults for a Proton-first workflow**

In Steam, set:

```text
Settings -> Compatibility
- enable Steam Play for supported titles
- enable Steam Play for all other titles
- default tool: Proton Experimental
```

Expected:

- Steam uses `Proton Experimental` by default
- `GE-Proton` appears as a per-game fallback tool after ProtonPlus installs it

- [ ] **Step 4: Set the Heroic defaults for Epic games**

In Heroic, set:

```text
Settings -> Defaults
- runner family: Proton or UMU-backed Proton
- keep GE-Proton available as a per-game override
- do not switch the global default to raw Wine
```

Expected:

- Epic titles default to Proton-style runners
- Wine remains available only as a compatibility fallback

- [ ] **Step 5: Deploy the dotfile changes and reload your shell**

Run:

```bash
cd ~/dotfiles
stow home hyprland
exec "$SHELL"
```

Expected:

- `~/.bash_aliases`, `~/.bash_functions`, `~/.zsh_aliases`, `~/.zsh_functions`, and `~/.local/share/bin/gamemode.sh` resolve to the updated stow-managed files
- the new `gcheck`, `gmodes`, and `pplus` commands are available

- [ ] **Step 6: Verify the stack from the terminal**

Run:

```bash
gcheck
gmodes
vulkaninfo --summary | rg 'deviceName|driverName'
```

Expected:

- `gcheck` shows Steam, Heroic, ProtonPlus, UMU, Gamescope, MangoHud, and GameMode
- `gmodes` prints the four suggested launch presets
- Vulkan still reports the Intel Iris Xe device and Mesa driver

- [ ] **Step 7: Verify one Steam game and one Epic game before changing defaults further**

Run these manual checks:

```text
1. launch one known-good Steam Proton title with default settings
2. launch one known-good Epic title from Heroic with default settings
3. if a title has focus, fullscreen, or pacing issues, retry it with one of the printed `gmodes` launch options
```

Expected:

- both launchers can boot at least one game
- no global Gamescope or MangoHud wrapper is needed yet
