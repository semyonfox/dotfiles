#!/usr/bin/env bash
# t_0e922822: small Ubuntu-only wrapper around the actual dotfiles package map.
# No passwords, upgrades, deployment, shell switch, daemons or Jenkins enrollment.
set -euo pipefail
repo="$HOME/dotfiles"
source "$repo/lib/common.sh"
source "$repo/lib/package-lists.sh"
[[ $(detect_os) == ubuntu && $(detect_package_manager) == apt ]] || { printf 'Ubuntu/APT required\n' >&2; exit 2; }
# Existing installer is interactive and also offers GUI/gaming/remote bootstrap.
# Select just shell core and useful CLI dependencies using its canonical mapping.
packages=()
for key in "${CRITICAL_PACKAGES[@]}" "${SHELL_CORE_PACKAGES[@]}" zsh ripgrep fzf eza bat fd zoxide; do
  packages+=("$(get_package_name "$key")")
done
# Explicit development / Jenkins Java prerequisites, not agent enrollment.
packages+=(git-lfs build-essential nodejs npm openjdk-21-jdk-headless)
mode="${1:---dry-run}"
[[ $# -le 1 ]] || exit 2
printf 'Repo revision: '; git -C "$repo" rev-parse HEAD
printf 'Scoped packages: %s\n' "${packages[*]}"
case "$mode" in
  --dry-run) exec apt-get --simulate --no-remove --no-upgrade --no-install-recommends install "${packages[@]}" ;;
  --install)
    # Interactive sudo and APT confirmation in the operator terminal only.
    sudo apt-get update
    sudo apt-get --no-remove --no-upgrade --no-install-recommends install "${packages[@]}"
    printf '\nInstalled package checks:\n'
    dpkg-query -W -f='${binary:Package} ${Version}\n' "${packages[@]}"
    java -version
    printf '\nNo restow, shell switch, login, service startup or Jenkins registration was performed.\n'
    ;;
  *) printf 'Usage: %s [--dry-run|--install]\n' "$0" >&2; exit 2 ;;
esac
