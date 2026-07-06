#!/usr/bin/env bash
# Machine-aware power profile helper.
#
# Profiles are selected by ~/.config/dotfiles/machine-profile, which is owned by
# host packages such as pc/, laptop/, and server/. Laptop writes go through the
# local privileged /usr/local/bin/power-mode-write helper when present.
set -euo pipefail

home_dir="${HOME:-/home/semyon}"
config_home="${XDG_CONFIG_HOME:-$home_dir/.config}"
cache_home="${XDG_CACHE_HOME:-$home_dir/.cache}"
profile_file="$config_home/dotfiles/machine-profile"
cache_file="$cache_home/power-mode"
writer="${POWER_MODE_WRITER:-/usr/local/bin/power-mode-write}"

machine_profile="${DOTFILES_MACHINE_PROFILE:-}"
if [[ -z "$machine_profile" ]]; then
    machine_profile="$(cat "$profile_file" 2>/dev/null || echo unknown)"
fi

mkdir -p "$(dirname "$cache_file")"

current_mode() {
    cat "$cache_file" 2>/dev/null || echo ac
}

write_mode() {
    printf '%s\n' "$1" > "$cache_file"
    pkill -RTMIN+8 waybar 2>/dev/null || true
}

has_battery() {
    compgen -G /sys/class/power_supply/BAT\* >/dev/null
}

ac_online() {
    local supply online
    for supply in /sys/class/power_supply/A{C,DP}* /sys/class/power_supply/ACAD*; do
        [[ -e "$supply/online" ]] || continue
        online="$(cat "$supply/online" 2>/dev/null || echo 0)"
        [[ "$online" == 1 ]] && return 0
    done
    ! has_battery
}

write_if_writable() {
    local value=$1 path=$2
    [[ -w "$path" ]] || return 0
    printf '%s\n' "$value" > "$path" 2>/dev/null || true
}

priv_write() {
    [[ -x "$writer" ]] || return 0
    sudo -n "$writer" "$@" >/dev/null 2>&1 || true
}

for_each_cpu() {
    local callback=$1 value=$2 cpu_path cpu_id
    for cpu_path in /sys/devices/system/cpu/cpu[0-9]*/cpufreq; do
        [[ -d "$cpu_path" ]] || continue
        cpu_id="$(basename "$(dirname "$cpu_path")" | tr -dc 0-9)"
        "$callback" "$cpu_id" "$value"
    done
}

set_governor_all() { for_each_cpu set_governor_one "$1"; }
set_epp_all() { for_each_cpu set_epp_one "$1"; }
set_epb_all() { for_each_cpu set_epb_one "$1"; }

set_governor_one() { priv_write governor "$2" "$1"; }
set_epp_one() { priv_write epp "$2" "$1"; }
set_epb_one() { priv_write epb "$2" "$1"; }
set_thresholds() { priv_write charge-start "$1"; priv_write charge-end "$2"; }

apply_desktop_performance() {
    local policy gpu

    for policy in /sys/devices/system/cpu/cpufreq/policy*; do
        [[ -d "$policy" ]] || continue
        grep -qw performance "$policy/scaling_available_governors" 2>/dev/null &&
            write_if_writable performance "$policy/scaling_governor"
        grep -qw performance "$policy/energy_performance_available_preferences" 2>/dev/null &&
            write_if_writable performance "$policy/energy_performance_preference"
    done

    while IFS= read -r gpu; do
        gpu="${gpu%/power_dpm_force_performance_level}"
        write_if_writable high "$gpu/power_dpm_force_performance_level"
        [[ -e "$gpu/pp_power_profile_mode" ]] &&
            write_if_writable 1 "$gpu/pp_power_profile_mode"
    done < <(find /sys/devices -name power_dpm_force_performance_level -type f 2>/dev/null)

    write_mode beast
}

apply_laptop() {
    local powerprofiles=$1 governor=$2 epp=$3 epb=$4 start=$5 end=$6 mode=$7

    set_governor_all "$governor"
    powerprofilesctl set "$powerprofiles" 2>/dev/null || true
    set_epp_all "$epp"
    set_epb_all "$epb"
    set_thresholds "$start" "$end"
    write_mode "$mode"
}

apply_laptop_beast() {
    apply_laptop performance performance performance 0 0 100 beast
}

apply_laptop_ac() {
    apply_laptop balanced powersave balance_performance 4 40 80 ac
}

apply_laptop_mobile() {
    apply_laptop balanced powersave balance_power 8 40 80 mobile
}

apply_laptop_saver() {
    apply_laptop power-saver powersave power 15 40 80 saver
}

apply_mode() {
    local requested=$1

    case "$machine_profile" in
        laptop)
            case "$requested" in
                beast|performance|apply) apply_laptop_beast ;;
                ac|balanced) apply_laptop_ac ;;
                mobile) apply_laptop_mobile ;;
                saver|power-saver) apply_laptop_saver ;;
                auto)
                    target="$(current_mode)"
                    if ! ac_online && [[ "$target" == beast ]]; then
                        target=mobile
                    fi
                    apply_mode "$target"
                    ;;
                on-ac)
                    :
                    ;;
                on-battery)
                    [[ "$(current_mode)" == beast ]] && apply_laptop_mobile || true
                    ;;
                *)
                    usage
                    ;;
            esac
            ;;
        pc|desktop)
            case "$requested" in
                beast|performance|apply|auto|ac|balanced|mobile|saver|power-saver|on-ac|on-battery)
                    apply_desktop_performance
                    ;;
                *)
                    usage
                    ;;
            esac
            ;;
        *)
            case "$requested" in
                status) ;;
                *) write_mode "$requested" ;;
            esac
            ;;
    esac
}

cycle() {
    case "$machine_profile:$(current_mode)" in
        laptop:ac) apply_laptop_beast ;;
        laptop:beast) apply_laptop_saver ;;
        laptop:saver) apply_laptop_mobile ;;
        laptop:mobile|laptop:*) apply_laptop_ac ;;
        *) apply_desktop_performance ;;
    esac
}

status() {
    local gov=none epp=none epb=none ppd=none gpu_dpm=none gpu_profile=none lact=inactive lact_profile=none

    gov="$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor 2>/dev/null || echo none)"
    epp="$(cat /sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference 2>/dev/null || echo none)"
    epb="$(cat /sys/devices/system/cpu/cpu0/power/energy_perf_bias 2>/dev/null || echo none)"
    ppd="$(powerprofilesctl get 2>/dev/null || echo none)"
    gpu_dpm="$(find /sys/devices -name power_dpm_force_performance_level -type f -exec cat {} \; 2>/dev/null | head -n1)"
    gpu_profile="$(find /sys/devices -name pp_power_profile_mode -type f -exec awk '/[*]/ {gsub(/[*:]/, "", $2); print $2; exit}' {} \; 2>/dev/null | head -n1)"
    [[ -n "$gpu_dpm" ]] || gpu_dpm=none
    [[ -n "$gpu_profile" ]] || gpu_profile=none

    if command -v lact >/dev/null 2>&1 && systemctl is-active --quiet lactd.service 2>/dev/null; then
        lact=active
        lact_profile="$(lact cli profile get 2>/dev/null | awk -F': ' '/Current profile/ {print $2; found=1} END {if (!found) print "none"}')"
    fi

    printf 'machine_profile: %s\nmode: %s\nac: %s\npowerprofilesctl: %s\ncpu_governor: %s\ncpu_epp: %s\ncpu_epb: %s\ngpu_dpm: %s\ngpu_profile: %s\nlact: %s\nlact_profile: %s\n' \
        "$machine_profile" \
        "$(current_mode)" \
        "$(ac_online && echo on || echo off)" \
        "$ppd" \
        "$gov" \
        "$epp" \
        "$epb" \
        "$gpu_dpm" \
        "$gpu_profile" \
        "$lact" \
        "$lact_profile"
}

usage() {
    echo "usage: $0 {beast|ac|mobile|saver|balanced|performance|apply|cycle|auto|on-ac|on-battery|status}" >&2
    exit 1
}

case "${1:-status}" in
    cycle) cycle ;;
    status) status ;;
    beast|ac|mobile|saver|balanced|performance|apply|auto|on-ac|on-battery|power-saver)
        apply_mode "$1"
        status
        ;;
    *) usage ;;
esac
