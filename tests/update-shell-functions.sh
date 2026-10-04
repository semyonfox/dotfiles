#!/usr/bin/env bash
set -u

if [[ $# -eq 0 ]]; then
    repo="$(cd "$(dirname "$0")/.." && pwd)"
    test_root="$(mktemp -d)"
    trap 'rm -rf "$test_root"' EXIT
    bash "$0" "$repo/home/.bash_functions" "$test_root/bash" || exit 1
    if command -v zsh >/dev/null 2>&1; then
        zsh "$0" "$repo/home/.zsh_functions" "$test_root/zsh" || exit 1
    else
        printf 'SKIP: zsh is unavailable\n'
    fi
    exit 0
fi

source_file=$1
test_root=$2
mkdir -p "$test_root/home/.local/bin"
export HOME="$test_root/home"
export TRACE="$test_root/trace"
export TEST_FAIL_STEP=

cat > "$HOME/.local/bin/update-ai-clis" <<'EOF'
#!/bin/sh
printf 'ai\n' >> "$TRACE"
[ "$TEST_FAIL_STEP" != ai ]
EOF
cat > "$HOME/.local/bin/update-pipx-venvs" <<'EOF'
#!/bin/sh
printf 'pipx-helper\n' >> "$TRACE"
[ "$TEST_FAIL_STEP" != pipx-helper ]
EOF
chmod +x "$HOME/.local/bin/update-ai-clis" "$HOME/.local/bin/update-pipx-venvs"

awk '/^update\(\) \{/{copy=1} copy {print} copy && /^\}/{exit}' "$source_file" > "$test_root/update.function"
source "$test_root/update.function"

paru() { printf 'paru\n' >> "$TRACE"; [[ "$TEST_FAIL_STEP" != paru ]]; }
flatpak() { printf 'flatpak\n' >> "$TRACE"; [[ "$TEST_FAIL_STEP" != flatpak ]]; }
rustup() { printf 'rustup\n' >> "$TRACE"; [[ "$TEST_FAIL_STEP" != rustup ]]; }
pnpm() {
    printf 'pnpm-%s\n' "$1" >> "$TRACE"
    [[ "$TEST_FAIL_STEP" != "pnpm-$1" ]]
}
pipx() { :; }
uv() {
    printf 'uv-%s-%s\n' "$1" "${2:-}" >> "$TRACE"
    [[ "$TEST_FAIL_STEP" != "uv-$1-${2:-}" ]]
}

for step in success paru ai flatpak rustup pnpm-self-update pnpm-update pipx-helper uv-tool-upgrade; do
    : > "$TRACE"
    if [[ $step == success ]]; then
        TEST_FAIL_STEP=
    else
        TEST_FAIL_STEP=$step
    fi
    export TEST_FAIL_STEP
    if update > "$test_root/output" 2>&1; then
        update_exit=0
    else
        update_exit=$?
    fi
    expected=1
    [[ $step == success ]] && expected=0
    if [[ $update_exit -ne $expected ]] || ! tail -n 1 "$TRACE" | grep -qx 'uv-tool-upgrade'; then
        printf 'FAIL: %s returned %s (expected %s) or stopped early\n' "$step" "$update_exit" "$expected" >&2
        exit 1
    fi
    printf 'PASS: %s returned %s; last step ran\n' "$step" "$update_exit"
done
