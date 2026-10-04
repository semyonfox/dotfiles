#!/usr/bin/env bash

set -e

SCRIPT_DIR="${INSTALLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
fixture=$(mktemp -d)
trap 'rm -r "$fixture"' EXIT
mkdir -p "$fixture/bin"
export TEST_CALLS="$fixture/calls"
export PATH="$fixture/bin:$PATH"
: > "$TEST_CALLS"

cat > "$fixture/bin/sudo" <<'STUB'
#!/usr/bin/env bash
printf 'sudo %s\n' "$*" >> "$TEST_CALLS"
[[ "$*" != 'apt install -y dooit' ]]
STUB

cat > "$fixture/bin/apt" <<'STUB'
#!/usr/bin/env bash
exit 99
STUB

cat > "$fixture/bin/curl" <<'STUB'
#!/usr/bin/env bash
printf 'curl %s\n' "$*" >> "$TEST_CALLS"
[[ "${TEST_CURL_FAIL:-0}" != 1 ]] || exit 22
while [[ $# -gt 0 ]]; do
    if [[ "$1" == -o ]]; then
        printf '# local fixture\n' > "$2"
        exit 0
    fi
    shift
done
exit 2
STUB

cat > "$fixture/bin/sh" <<'STUB'
#!/usr/bin/env bash
[[ -s "$1" ]] || exit 2
printf 'sh %s\n' "$2" >> "$TEST_CALLS"
STUB

chmod +x "$fixture/bin/sudo" "$fixture/bin/apt" "$fixture/bin/curl" "$fixture/bin/sh"

source "$SCRIPT_DIR/install-deps.sh"
get_base_os() { echo ubuntu; }
LOG_FILE="$fixture/install.log"
: > "$LOG_FILE"

PKG_MANAGER=apt
INSTALL_CMD=$(get_install_command "$PKG_MANAGER")
CRITICAL_PACKAGES=(stow)
SHELL_CORE_PACKAGES=()
SHELL_UTILITY_PACKAGES=()
PACKAGES_TO_INSTALL=(stow dooit thefuck)
install_packages > "$fixture/output"

mapfile -t calls < "$TEST_CALLS"
[[ "${calls[0]}" == 'sudo apt update' ]]
[[ "${calls[1]}" == 'sudo apt install -y stow' ]]
[[ "${calls[2]}" == 'sudo apt install -y dooit' ]]
[[ "${calls[3]}" == 'sudo apt install -y thefuck' ]]
[[ "${#calls[@]}" == 4 ]]
[[ "${FAILED_OPTIONAL_PACKAGES[*]}" == dooit ]]
[[ "${INSTALLED_PACKAGES[*]}" == 'stow thefuck' ]]
show_install_summary > "$fixture/summary"
rg -q 'FAILED OPTIONAL PACKAGES \(1 - skipped\)' "$fixture/summary"
rg -q '✗ dooit' "$fixture/summary"

if (detect_package_manager() { echo unknown; }; show_system_info) > "$fixture/unsupported-output" 2>&1; then
    echo 'unknown package manager was accepted' >&2
    exit 1
fi

export TEST_CURL_FAIL=1
if install_omz_remote; then
    echo 'failed download was reported as success' >&2
    exit 1
fi
! rg -q '^sh ' "$TEST_CALLS"

export TEST_CURL_FAIL=0
install_omz_remote
[[ "$(rg -c '^sh --unattended$' "$TEST_CALLS")" == 1 ]]

echo 'dependency installer stub tests passed'
