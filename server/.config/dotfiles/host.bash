# Server-only interactive shell overrides.

update() {
    local failed=0 step=0 total=7 disk before_used after_used reboot t3_update
    local -a failed_steps=() skipped=()
    _update_failed() { printf '!! %s failed\n' "$1"; failed=1; failed_steps+=("$1"); }
    _update_skip() { printf '      %s not installed, skipping\n' "$1"; skipped+=("$1"); }

    _maint_box '1;97' 'Server update'
    disk=$(_maint_disk)
    before_used=${disk%% *}

    _maint_step $((++step)) "$total" 'system packages (apt)'
    sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y && sudo apt autoclean || _update_failed apt

    _maint_step $((++step)) "$total" 'snap'
    if command -v snap >/dev/null 2>&1; then
        sudo snap refresh || _update_failed snap
    else
        _update_skip snap
    fi

    _maint_step $((++step)) "$total" 'AI CLIs'
    "$HOME/.local/bin/update-ai-clis" || _update_failed 'AI CLIs'
    hash -r
    if command -v npm >/dev/null 2>&1; then
        npm install -g npm@latest || _update_failed npm
    fi

    _maint_step $((++step)) "$total" 'T3 Code nightly'
    t3_update="$HOME/bin/t3-headless-update"
    if [[ -x "$t3_update" ]]; then
        "$t3_update" || _update_failed 'T3 Code'
    else
        printf '!! T3 Code updater not found: %s\n' "$t3_update"
        failed=1 failed_steps+=('T3 Code')
    fi

    _maint_step $((++step)) "$total" 'pipx'
    if command -v pipx >/dev/null 2>&1; then
        "$HOME/.local/bin/update-pipx-venvs" || _update_failed pipx
    else
        _update_skip pipx
    fi

    _maint_step $((++step)) "$total" 'uv tools'
    if command -v uv >/dev/null 2>&1; then
        uv self update 2>/dev/null || true
        uv tool upgrade --all || _update_failed uv
    else
        _update_skip uv
    fi

    _maint_step $((++step)) "$total" 'versions'
    command -v t3 >/dev/null 2>&1 && printf '      t3        %s\n' "$(t3 --version 2>/dev/null)"
    command -v codex >/dev/null 2>&1 && printf '      codex     %s\n' "$(codex --version 2>/dev/null)"
    command -v claude >/dev/null 2>&1 && printf '      claude    %s\n' "$(claude --version 2>/dev/null)"
    command -v opencode >/dev/null 2>&1 && printf '      opencode  %s\n' "$(opencode --version 2>/dev/null)"

    unset -f _update_failed _update_skip
    disk=$(_maint_disk)
    after_used=${disk%% *}
    reboot=$(_maint_reboot_reason)
    local -a lines=()
    (( ${#failed_steps[@]} )) && lines+=("Failed:   ${failed_steps[*]}")
    (( ${#skipped[@]} )) && lines+=("Skipped:  ${skipped[*]}")
    lines+=("Disk:     $(_maint_human $(( ${after_used:-0} - ${before_used:-0} ))) change on /")
    lines+=("Reboot:   ${reboot:-not needed}")
    if [[ $failed -ne 0 ]]; then
        _maint_box '1;91' 'Update finished with failures' "${lines[@]}"
    else
        _maint_box '1;92' 'Everything is up to date' "${lines[@]}"
    fi
    if [[ -n $reboot && -f /var/run/reboot-required.pkgs ]]; then
        printf '\nPackages asking for a reboot:\n'
        sed 's/^/  /' /var/run/reboot-required.pkgs
    fi
    return "$failed"
}
