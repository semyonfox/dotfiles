#!/usr/bin/env bash
set -u

if [[ ${1:-} != --run ]]; then
    repo="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
    test_root="$(mktemp -d)"
    trap 'rm -rf "$test_root"' EXIT
    bash "$0" --run "$repo/home/.bash_functions" "$test_root/bash" || exit 1
    if command -v zsh >/dev/null 2>&1; then
        zsh "$0" --run "$repo/home/.zsh_functions" "$test_root/zsh" || exit 1
    else
        printf 'SKIP: zsh is unavailable\n'
    fi
    exit 0
fi

source_file=$2
test_root=$3
mkdir -p "$test_root/home"
export HOME="$test_root/home"
export TRACE="$test_root/trace"

# Only the cleanup definition is loaded, so no startup code or unrelated functions run.
awk '/^cleanup\(\) \{/{copy=1} copy {print} copy && /^\}/{exit}' "$source_file" > "$test_root/cleanup.function"
source "$test_root/cleanup.function"

du() { :; }
df() { printf 'Filesystem Size Used Avail Use%% Mounted on\nroot 1G 0 1G 0%% /\n'; }
id() { printf '1000\n'; }
pgrep() {
    if [[ -n ${MOCK_PGREP_ERROR_TARGET:-} ]]; then
        local target
        case "$*" in
            *'-x uv') target=uv ;;
            *GradleDaemon*) target=gradle ;;
            *ms-playwright*) target=playwright ;;
            *'_npx'*) target=npx ;;
        esac
        [[ $target == "$MOCK_PGREP_ERROR_TARGET" ]] && return 2
        return 1
    fi
    return "$MOCK_PGREP_STATUS"
}
uv() { printf 'uv %s\n' "$*" >> "$TRACE"; }
npm() { printf 'npm %s\n' "$*" >> "$TRACE"; }
pnpm() { printf 'pnpm %s\n' "$*" >> "$TRACE"; }
pip3() { printf 'pip3 %s\n' "$*" >> "$TRACE"; }
rm() {
    [[ ${3:-} == "$HOME/"* ]] || return 99
    printf 'rm %s\n' "$3" >> "$TRACE"
}

MOCK_PGREP_ERROR_TARGET=
for MOCK_PGREP_STATUS in 0 1 2; do
    : > "$TRACE"
    if cleanup --deep > "$test_root/output" 2>&1; then
        cleanup_exit=0
    else
        cleanup_exit=$?
    fi
    action_count=$(grep -Ec '^(uv|rm) ' "$TRACE" || true)
    case $MOCK_PGREP_STATUS in
        0) expected_exit=0; expected_actions=0 ;;
        1) expected_exit=0; expected_actions=4 ;;
        2) expected_exit=1; expected_actions=0 ;;
    esac
    if [[ $cleanup_exit -ne $expected_exit || $action_count -ne $expected_actions ]] \
        || ! grep -q '^pip3 cache purge$' "$TRACE"; then
        printf 'FAIL: pgrep=%s yielded exit=%s, cleanup actions=%s\n' \
            "$MOCK_PGREP_STATUS" "$cleanup_exit" "$action_count" >&2
        exit 1
    fi
    printf 'PASS: pgrep=%s yielded exit=%s, cleanup actions=%s\n' \
        "$MOCK_PGREP_STATUS" "$cleanup_exit" "$action_count"
done

for MOCK_PGREP_ERROR_TARGET in uv gradle playwright npx; do
    : > "$TRACE"
    if cleanup --deep > "$test_root/output" 2>&1; then
        cleanup_exit=0
    else
        cleanup_exit=$?
    fi
    action_count=$(grep -Ec '^(uv|rm) ' "$TRACE" || true)
    case $MOCK_PGREP_ERROR_TARGET in
        uv) forbidden='uv cache prune' ;;
        gradle) forbidden="rm $HOME/.gradle/caches" ;;
        playwright) forbidden="rm $HOME/.cache/ms-playwright" ;;
        npx) forbidden="rm $HOME/.npm/_npx" ;;
    esac
    if [[ $cleanup_exit -ne 1 || $action_count -ne 3 ]] \
        || grep -Fxq "$forbidden" "$TRACE"; then
        printf 'FAIL: %s check error yielded exit=%s, cleanup actions=%s\n' \
            "$MOCK_PGREP_ERROR_TARGET" "$cleanup_exit" "$action_count" >&2
        exit 1
    fi
    printf 'PASS: %s check error skipped its target; other cleanup ran\n' \
        "$MOCK_PGREP_ERROR_TARGET"
done
