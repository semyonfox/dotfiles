#!/usr/bin/env bash
# unified power-mode orchestrator for x1 carbon gen 9
# modes: beast | balanced | saver
# rule: auto transitions only go DOWN. manual cycle goes anywhere.
#   - unplug while beast -> drop to balanced (beast is AC-only)
#   - everything else: stay where you are (you set it for a reason)
# cycle order (waybar click): balanced -> beast -> saver -> balanced
#
# intel_pstate quirk: EPP can only be written while governor=powersave.
# governor must be set BEFORE EPP, otherwise the EPP write fails with EBUSY.
set -euo pipefail

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/power-mode"
mkdir -p "$(dirname "$CACHE")"
WRITER=/usr/local/bin/power-mode-write

current_mode() { [ -f "$CACHE" ] && cat "$CACHE" || echo balanced; }
ac_online()    { [ "$(cat /sys/class/power_supply/AC/online 2>/dev/null)" = "1" ]; }
w() { sudo -n "$WRITER" "$@" >/dev/null 2>&1 || true; }

for_each_cpu() { local i; for i in /sys/devices/system/cpu/cpu[0-9]*/cpufreq; do "$1" "$(basename "$(dirname "$i")" | tr -dc 0-9)" "$2"; done; }
set_governor_all() { for_each_cpu '_gov' "$1"; }
set_epp_all()      { for_each_cpu '_epp' "$1"; }
set_epb_all()      { for_each_cpu '_epb' "$1"; }
_gov() { w governor "$2" "$1"; }
_epp() { w epp      "$2" "$1"; }
_epb() { w epb      "$2" "$1"; }
set_thresholds() { w charge-start "$1"; w charge-end "$2"; }

apply() {
    local profile=$1 governor=$2 epp=$3 epb=$4 cstart=$5 cend=$6 name=$7
    set_governor_all "$governor"            # FIRST: frees EPP from intel_pstate EBUSY lock
    powerprofilesctl set "$profile" 2>/dev/null || true
    set_epp_all "$epp"
    set_epb_all "$epb"
    set_thresholds "$cstart" "$cend"
    echo "$name" > "$CACHE"
    pkill -RTMIN+8 waybar 2>/dev/null || true
}

# intel_pstate: governor=performance locks EPP=performance. so beast is fully
# performance everywhere; balanced/saver use governor=powersave to allow EPP.
apply_beast()    { apply performance performance performance         0  0  100 beast;    }
apply_balanced() { apply balanced    powersave   balance_performance 4  40 80  balanced; }
apply_saver()    { apply power-saver powersave   power               15 40 80  saver;    }

re_apply() {
    case "$1" in
        beast) apply_beast ;;
        saver) apply_saver ;;
        *)     apply_balanced ;;
    esac
}

cycle() {
    case "$(current_mode)" in
        balanced) apply_beast ;;
        beast)    apply_saver ;;
        *)        apply_balanced ;;
    esac
}

case "${1:-status}" in
    beast)    apply_beast ;;
    balanced) apply_balanced ;;
    saver)    apply_saver ;;
    cycle)    cycle ;;
    on-ac)    : ;;                              # plug-in: never auto-upgrade
    on-battery)                                 # unplug: drop beast only
        [ "$(current_mode)" = "beast" ] && apply_balanced || :
        ;;
    auto)                                       # boot/resume: re-apply, downgrade beast on battery
        target="$(current_mode)"
        if ! ac_online && [ "$target" = "beast" ]; then target=balanced; fi
        re_apply "$target"
        ;;
    status)
        printf 'mode: %s\nac: %s\nppd: %s\ngov: %s\nepp: %s\nepb: %s\nthresholds: %s-%s\n' \
            "$(current_mode)" \
            "$(ac_online && echo on || echo off)" \
            "$(powerprofilesctl get 2>/dev/null)" \
            "$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)" \
            "$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null)" \
            "$(cat /sys/devices/system/cpu/cpu0/power/energy_perf_bias 2>/dev/null)" \
            "$(cat /sys/class/power_supply/BAT0/charge_control_start_threshold 2>/dev/null)" \
            "$(cat /sys/class/power_supply/BAT0/charge_control_end_threshold 2>/dev/null)"
        ;;
    *)
        echo "usage: $0 {beast|balanced|saver|cycle|auto|on-ac|on-battery|status}" >&2
        exit 1 ;;
esac
