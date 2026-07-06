# Server-only interactive shell overrides.

update() {
    local reboot_pkgs

    echo "==> system (apt)"
    sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y && sudo apt autoclean || echo "!! apt failed"

    echo ""
    echo "==> snap"
    if command -v snap >/dev/null 2>&1; then
        sudo snap refresh || echo "!! snap failed"
    else
        echo "snap not installed"
    fi

    echo ""
    echo "==> npm global CLIs"
    if command -v npm >/dev/null 2>&1; then
        npm install -g \
            npm@latest \
            @anthropic-ai/claude-code@latest \
            @google/gemini-cli@latest \
            @openai/codex@latest \
            opencode-ai@latest \
            t3@nightly || echo "!! npm globals failed"
    else
        echo "npm not installed"
    fi

    echo ""
    echo "==> Claude Code self-update"
    if command -v claude >/dev/null 2>&1; then
        claude update || echo "!! claude update failed"
    else
        echo "claude not installed"
    fi

    echo ""
    echo "==> pipx"
    if command -v pipx >/dev/null 2>&1; then
        pipx upgrade-all || echo "!! pipx failed"
    else
        echo "pipx not installed"
    fi

    echo ""
    echo "==> uv tools"
    if command -v uv >/dev/null 2>&1; then
        uv self update 2>/dev/null || true
        uv tool upgrade --all || echo "!! uv failed"
    else
        echo "uv not installed"
    fi

    echo ""
    echo "==> T3 headless service"
    if systemctl --user cat t3-code-headless.service >/dev/null 2>&1; then
        systemctl --user restart t3-code-headless.service || echo "!! t3 service restart failed"
        systemctl --user --no-pager --full status t3-code-headless.service | sed -n "1,12p"
    else
        echo "t3-code-headless.service not found"
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
}
