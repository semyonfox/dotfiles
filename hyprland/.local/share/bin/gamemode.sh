#!/usr/bin/env bash

set -e

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
STATE_FILE="$CACHE_DIR/hypr-gaming-mode"
GAMEMODE_PID="$CACHE_DIR/hypr-gaming-mode-pid"
WAYBAR_STYLE="$HOME/.config/waybar/style.css"

read_option() {
    local option="$1"
    local line value

    line=$(hyprctl getoption "$option" | awk '$1 != "set:" { print; exit }')
    value=${line#*: }

    case "$option" in
        decoration:blur:enabled|animations:enabled)
            [[ "$value" == "0" ]] && printf 'false\n' || printf 'true\n'
            ;;
        *)
            printf '%s\n' "$value"
            ;;
    esac
}

notify() {
    if command -v notify-send &>/dev/null; then
        notify-send "gaming mode" "$1"
    fi
}

waybar_toggle() {
    local mode="$1"

    [[ -f "$WAYBAR_STYLE" ]] || return 0

    # always uncomment first (restore)
    sed -i 's|/\* \(.*animation:.*\) \*/|\1|g' "$WAYBAR_STYLE"
    sed -i 's|/\* \(.*transition:.*\) \*/|\1|g' "$WAYBAR_STYLE"

    if [[ "$mode" == "on" ]]; then
        # comment out animations and transitions
        sed -i 's|^\(.*animation:.*\)$|/* \1 */|g' "$WAYBAR_STYLE"
        sed -i 's|^\(.*transition:.*\)$|/* \1 */|g' "$WAYBAR_STYLE"
    fi

    killall waybar 2>/dev/null || true
    waybar >/dev/null 2>&1 &
}

if [[ -f "$STATE_FILE" ]]; then
    # restore saved values
    source "$STATE_FILE"
    hyprctl --batch "\
        keyword animations:enabled $ANIMATIONS_ENABLED;\
        keyword decoration:blur:enabled $BLUR_ENABLED;\
        keyword decoration:rounding $ROUNDING;\
        keyword general:gaps_in $GAPS_IN;\
        keyword general:gaps_out $GAPS_OUT;\
        keyword general:border_size $BORDER_SIZE"

    waybar_toggle off

    if [[ -f "$GAMEMODE_PID" ]]; then
        kill "$(cat "$GAMEMODE_PID")" 2>/dev/null || true
        rm -f "$GAMEMODE_PID"
    fi

    rm -f "$STATE_FILE"
    notify "off"
else
    # save current values before overriding
    mkdir -p "$CACHE_DIR"
    {
        printf 'ANIMATIONS_ENABLED=%q\n' "$(read_option animations:enabled)"
        printf 'BLUR_ENABLED=%q\n' "$(read_option decoration:blur:enabled)"
        printf 'ROUNDING=%q\n' "$(read_option decoration:rounding)"
        printf 'GAPS_IN=%q\n' "$(read_option general:gaps_in)"
        printf 'GAPS_OUT=%q\n' "$(read_option general:gaps_out)"
        printf 'BORDER_SIZE=%q\n' "$(read_option general:border_size)"
    } > "$STATE_FILE"

    hyprctl --batch "\
        keyword animations:enabled false;\
        keyword decoration:blur:enabled false;\
        keyword decoration:rounding 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1"

    waybar_toggle on

    if command -v gamemoderun &>/dev/null; then
        gamemoderun sleep infinity &
        printf '%s\n' "$!" > "$GAMEMODE_PID"
    fi

    notify "on"
fi
