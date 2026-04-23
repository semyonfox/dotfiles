#!/usr/bin/env bash
# unified power-mode orchestrator for x1 carbon gen 9
# modes: beast | ac | mobile | saver | auto | cycle | status | on-ac | on-battery
set -euo pipefail

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/power-mode"
mkdir -p "$(dirname "$CACHE")"

WRITER=/usr/local/bin/power-mode-write

current_mode() { [ -f "$CACHE" ] && cat "$CACHE" || echo ac; }
ac_online()    { [ "$(cat /sys/class/power_supply/AC/online 2>/dev/null)" = "1" ]; }

w() { sudo -n "$WRITER" "$@" >/dev/null 2>&1 || true; }

set_thresholds() { w charge-start "$1"; w charge-end "$2"; }
set_epp_all()    { local i; for i in /sys/devices/system/cpu/cpu[0-9]*/cpufreq; do w epp "$1" "$(basename "$(dirname "$i")" | tr -dc 0-9)"; done; }
set_epb_all()    { local i; for i in /sys/devices/system/cpu/cpu[0-9]*/power; do w epb "$1" "$(basename "$(dirname "$i")" | tr -dc 0-9)"; done; }

apply() {
    local profile=$1 epp=$2 epb=$3 cstart=$4 cend=$5 name=$6
    powerprofilesctl set "$profile" 2>/dev/null || true
    set_epp_all "$epp"
    set_epb_all "$epb"
    set_thresholds "$cstart" "$cend"
    echo "$name" > "$CACHE"
    pkill -RTMIN+8 waybar 2>/dev/null || true
}

apply_beast()  { apply performance balance_performance 0  0  100 beast;  }
apply_ac()     { apply balanced    balance_performance 4  40 80  ac;     }
apply_mobile() { apply balanced    balance_power       8  40 80  mobile; }
apply_saver()  { apply power-saver power               15 40 80  saver;  }

cycle() {
    case "$(current_mode)" in
        ac)     apply_beast  ;;
        beast)  apply_mobile ;;
        mobile) apply_saver  ;;
        *)      apply_ac     ;;
    esac
}

case "${1:-status}" in
    beast)   apply_beast  ;;
    ac)      apply_ac     ;;
    mobile)  apply_mobile ;;
    saver)   apply_saver  ;;
    cycle)   cycle ;;
    auto)    if ac_online; then apply_ac; else apply_mobile; fi ;;
    on-ac)
        case "$(current_mode)" in beast|saver) ;; *) apply_ac ;; esac
        ;;
    on-battery)
        case "$(current_mode)" in beast|saver) ;; *) apply_mobile ;; esac
        ;;
    status)
        printf 'mode: %s\nac: %s\nppd: %s\nepp: %s\nepb: %s\nthresholds: %s-%s\n' \
            "$(current_mode)" \
            "$(ac_online && echo on || echo off)" \
            "$(powerprofilesctl get 2>/dev/null)" \
            "$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null)" \
            "$(cat /sys/devices/system/cpu/cpu0/power/energy_perf_bias 2>/dev/null)" \
            "$(cat /sys/class/power_supply/BAT0/charge_control_start_threshold 2>/dev/null)" \
            "$(cat /sys/class/power_supply/BAT0/charge_control_end_threshold 2>/dev/null)"
        ;;
    *) echo "usage: $0 {beast|ac|mobile|saver|auto|cycle|status|on-ac|on-battery}" >&2; exit 1 ;;
esac
