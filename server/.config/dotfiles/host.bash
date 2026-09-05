# Server-only interactive shell overrides.

update() {
    local reboot_pkgs t3_update update_failed=0

    echo "==> system (apt)"
    sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y && sudo apt autoclean || { echo "!! apt failed"; update_failed=1; }

    echo ""
    echo "==> snap"
    if command -v snap >/dev/null 2>&1; then
        sudo snap refresh || { echo "!! snap failed"; update_failed=1; }
    else
        echo "snap not installed"
    fi

    echo ""
    echo "==> AI CLIs"
    "$HOME/.local/bin/update-ai-clis" || update_failed=1
    hash -r

    if command -v npm >/dev/null 2>&1; then
        npm install -g npm@latest || { echo "!! npm update failed"; update_failed=1; }
    fi

    echo ""
    echo "==> T3 Code nightly"
    t3_update="$HOME/bin/t3-headless-update"
    if [[ -x "$t3_update" ]]; then
        "$t3_update" || { echo "!! T3 Code update failed"; update_failed=1; }
    else
        echo "!! T3 Code updater not found: $t3_update"
        update_failed=1
    fi

    echo ""
    echo "==> pipx"
    if command -v pipx >/dev/null 2>&1; then
        pipx upgrade-all || { echo "!! pipx failed"; update_failed=1; }
    else
        echo "pipx not installed"
    fi

    echo ""
    echo "==> uv tools"
    if command -v uv >/dev/null 2>&1; then
        uv self update 2>/dev/null || true
        uv tool upgrade --all || { echo "!! uv failed"; update_failed=1; }
    else
        echo "uv not installed"
    fi

    echo ""
    echo "==> versions"
    command -v t3 >/dev/null 2>&1 && t3 --version || true
    command -v codex >/dev/null 2>&1 && codex --version || true
    command -v claude >/dev/null 2>&1 && claude --version || true
    command -v opencode >/dev/null 2>&1 && opencode --version || true

    if [[ -f /var/run/reboot-required ]]; then
        echo ""
        echo "==> reboot required"
        reboot_pkgs="$(cat /var/run/reboot-required.pkgs 2>/dev/null || true)"
        [[ -n "$reboot_pkgs" ]] && echo "$reboot_pkgs"
    fi
    return "$update_failed"
}
