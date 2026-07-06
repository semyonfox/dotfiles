#!/usr/bin/env bash
set -euo pipefail

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hyprpaper-cycle"
state_file="$state_dir/current"
config="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprpaper.conf"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

wallpaper_dirs=(
    "$HOME/Wallpapers"
)

ensure_hypr_env() {
    local runtime_dir hypr_dir wayland_socket

    runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    [[ -d "$runtime_dir" ]] || return

    export XDG_RUNTIME_DIR="$runtime_dir"
    if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" && -d "$runtime_dir/hypr" ]]; then
        hypr_dir="$(find "$runtime_dir/hypr" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | head -1)"
        [[ -n "$hypr_dir" ]] && export HYPRLAND_INSTANCE_SIGNATURE="$hypr_dir"
    fi

    if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
        wayland_socket="$(find "$runtime_dir" -maxdepth 1 -type s -name 'wayland-*' -printf '%f\n' 2>/dev/null | head -1)"
        [[ -n "$wayland_socket" ]] && export WAYLAND_DISPLAY="$wayland_socket"
    fi

    export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-Hyprland}"
    export XDG_SESSION_TYPE="${XDG_SESSION_TYPE:-wayland}"
}

find_wallpapers() {
    local dir
    for dir in "${wallpaper_dirs[@]}"; do
        [[ -d "$dir" ]] || continue
        find "$dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \)
    done | sort -u
}

monitor_names() {
    if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
        hyprctl monitors -j 2>/dev/null | jq -r '.[].name' 2>/dev/null || true
    fi
}

current_index() {
    local current="$1"
    shift
    local i=0
    for wall in "$@"; do
        [[ "$wall" == "$current" ]] && {
            printf '%s\n' "$i"
            return
        }
        i=$((i + 1))
    done
    printf '0\n'
}

select_wallpaper() {
    local selected_index rofi_style rofi_conf_style rofi_scale hypr_border hypr_width wind_border elem_border r_override r_scale i_override wall display
    if command -v rofi >/dev/null 2>&1; then
        rofi_style="$HOME/.config/rofi/selector.rasi"
        [[ -r "$rofi_style" ]] || rofi_style="$HOME/.config/rofi/styles/style_1.rasi"
        if [[ -r "$HOME/.config/hyde/hyde.conf" ]]; then
            rofi_conf_style="$(awk -F= '/^rofiStyle=/{gsub(/"/, "", $2); print $2; exit}' "$HOME/.config/hyde/hyde.conf")"
            [[ -n "${rofi_conf_style:-}" && -r "$HOME/.config/rofi/styles/style_${rofi_conf_style}.rasi" ]] && rofi_style="$HOME/.config/rofi/styles/style_${rofi_conf_style}.rasi"
        fi
        [[ -r "$rofi_style" ]] || rofi_style="$(find "$HOME/.config/rofi/styles" -type f -name 'style_*.rasi' 2>/dev/null | sort -t '_' -k 2 -n | head -1)"

        rofi_scale=10
        hypr_border="$(hyprctl -j getoption decoration:rounding 2>/dev/null | jq -r '.int // 5' 2>/dev/null || printf '5')"
        hypr_width="$(hyprctl -j getoption general:border_size 2>/dev/null | jq -r '.int // 0' 2>/dev/null || printf '0')"
        wind_border=$(( hypr_border * 3 ))
        if (( hypr_border == 0 )); then
            elem_border=10
        else
            elem_border=$(( hypr_border * 2 ))
        fi
        r_scale="configuration {font: \"JetBrainsMono Nerd Font ${rofi_scale}\";}"
        r_override="window {border: ${hypr_width}px; border-radius: ${wind_border}px;} listview {columns: 4; spacing: 0.5em;} element {orientation: vertical; border-radius: ${elem_border}px; padding: 0.5em;} element-icon {size: 5em; border-radius: ${elem_border}px;} element-text {padding: 0.3em 0 0 0;}"
        i_override="configuration {icon-theme: \"$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | sed "s/'//g")\";}"

        selected_index="$(
            for wall in "$@"; do
                display="${wall#$HOME/Wallpapers/}"
                printf '%s\x00icon\x1f%s\n' "$display" "$wall"
            done | rofi -dmenu -i -p wallpaper -format i -theme-str "$r_scale" -theme-str "$r_override" -theme-str "$i_override" -config "$rofi_style"
        )" || return 1
        [[ "$selected_index" =~ ^[0-9]+$ ]] || return 1
        printf '%s\n' "${@:selected_index+1:1}"
        return
    fi

    printf '%s\n' "${1:-}"
}

write_config() {
    local wall="$1"
    shift
    local monitors=("$@")

    mkdir -p "$(dirname "$config")"
    {
        printf 'ipc = on\n'
        printf 'splash = false\n\n'
        printf 'preload = %s\n' "$wall"

        if (( ${#monitors[@]} == 0 )); then
            printf 'wallpaper = ,%s\n' "$wall"
        else
            local mon
            for mon in "${monitors[@]}"; do
                printf 'wallpaper = %s,%s\n' "$mon" "$wall"
            done
        fi
    } > "$config"
}

apply_wallpaper() {
    local wall="$1"
    shift
    local monitors=("$@")

    mkdir -p "$state_dir"
    printf '%s\n' "$wall" > "$state_file"

    if ! command -v hyprpaper >/dev/null 2>&1; then
        if command -v swwwallpaper.sh >/dev/null 2>&1; then
            swwwallpaper.sh -s "$wall"
            return
        elif [[ -x "$script_dir/swwwallpaper.sh" ]]; then
            "$script_dir/swwwallpaper.sh" -s "$wall"
            return
        fi
        return 1
    fi

    write_config "$wall" "${monitors[@]}"

    if ! pgrep -x hyprpaper >/dev/null 2>&1; then
        nohup hyprpaper >/tmp/hyprpaper.log 2>&1 &
        sleep 0.4
    fi

    if command -v hyprctl >/dev/null 2>&1; then
        local mon
        timeout 2 hyprctl hyprpaper preload "$wall" >/dev/null 2>&1 || true
        for mon in "${monitors[@]}"; do
            timeout 2 hyprctl hyprpaper wallpaper "$mon,$wall" >/dev/null 2>&1 || true
        done
    fi
}

ensure_hypr_env

mapfile -t wallpapers < <(find_wallpapers)
(( ${#wallpapers[@]} > 0 )) || exit 0
mapfile -t monitors < <(monitor_names)

action="${1:-current}"
current=""
[[ -r "$state_file" ]] && current="$(<"$state_file")"
[[ -n "$current" && -f "$current" ]] || current="${wallpapers[0]}"
idx="$(current_index "$current" "${wallpapers[@]}")"

case "$action" in
    next|-n)
        idx=$(( (idx + 1) % ${#wallpapers[@]} ))
        wall="${wallpapers[$idx]}"
        ;;
    prev|-p)
        idx=$(( (idx + ${#wallpapers[@]} - 1) % ${#wallpapers[@]} ))
        wall="${wallpapers[$idx]}"
        ;;
    random)
        wall="${wallpapers[$((RANDOM % ${#wallpapers[@]}))]}"
        ;;
    select)
        wall="$(select_wallpaper "${wallpapers[@]}")"
        [[ -n "$wall" ]] || exit 0
        ;;
    current|*)
        wall="$current"
        ;;
esac

apply_wallpaper "$wall" "${monitors[@]}"
