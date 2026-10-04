-- Hyprland Lua configuration for ThinkPad X1 Carbon Gen 9 (Laptop).
-- Migrated to native Hyprland Lua mode for 0.56+.

local home = os.getenv("HOME")
local scripts = home .. "/.local/share/bin"
package.path = home .. "/.config/hypr/?.lua;" .. package.path

-- Laptop display topology (ThinkPad internal display + dual external Dell monitors)
hl.monitor({
    output = "desc:Dell Inc. DELL G2422HS 6TG6XJ3",
    mode = "1920x1080@165.00",
    position = "3456x0",
    scale = 1,
})
hl.monitor({
    output = "desc:Dell Inc. DELL G2422HS G6H6XJ3",
    mode = "1920x1080@165.00",
    position = "1536x0",
    scale = 1,
})
hl.monitor({
    output = "eDP-1",
    mode = "1920x1200@60.00",
    position = "0x0",
    scale = 1.25,
})
hl.monitor({
    output = "WAYLAND-1",
    mode = "1280x720@60.00",
    position = "5376x0",
    scale = 1,
})
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1,
})

hl.workspace_rule({
    workspace = "1",
    monitor = "desc:Dell Inc. DELL G2422HS G6H6XJ3",
    default = true,
})
hl.workspace_rule({
    workspace = "5",
    monitor = "desc:Dell Inc. DELL G2422HS 6TG6XJ3",
    default = true,
})

-- Touchpad configuration for laptop
hl.config({
    input = {
        touchpad = {
            natural_scroll = true,
        },
    },
})

-- Session startup daemons
hl.on("hyprland.start", function()
    local commands = {
        scripts .. "/resetxdgportal.sh",
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
        "dbus-update-activation-environment --systemd --all",
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
        scripts .. "/polkitkdeauth.sh",
        "noctalia --daemon",
        "blueman-applet",
        "udiskie --no-automount --smart-tray",
        "nm-applet --indicator",
        home .. "/.local/bin/power-mode.sh auto",
        "playerctl daemon",
    }
    for _, command in ipairs(commands) do
        hl.exec_cmd(command)
    end
end)

-- Load shared Hyprland configuration (layouts, theme, rules, common binds)
local common = require("common")
common.setup({legacy_shell_binds = false})

-- Laptop-only power mode shortcuts
local main = "SUPER"
hl.bind(main .. " + F10", common.exec(home .. "/.local/bin/power-mode.sh saver"))
hl.bind(main .. " + F11", common.exec(home .. "/.local/bin/power-mode.sh ac"))
hl.bind(main .. " + F12", common.exec(home .. "/.local/bin/power-mode.sh beast"))
hl.bind(main .. " + SHIFT + F12", common.exec(home .. "/.local/bin/power-mode.sh cycle"))

-- Keep this literal require in the entrypoint: Noctalia's template hook detects it.
common.apply_noctalia_theme(function()
    return require("noctalia")
end)
