-- Hyprland Lua configuration for ThinkPad X1 Carbon Gen 9 (Laptop).
-- Migrated to native Hyprland Lua mode for 0.56+.

local home = os.getenv("HOME")
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

-- number the screens left to right, so whatever is plugged in shows 1..n.
-- focusing a workspace on the current monitor pulls it over if another screen
-- had it, which keeps the numbering stable across hotplug
local function number_workspaces_by_monitor()
    local monitors = {}
    for _, monitor in ipairs(hl.get_monitors()) do
        if not monitor.is_mirror then
            table.insert(monitors, monitor)
        end
    end
    table.sort(monitors, function(a, b)
        if a.position.x ~= b.position.x then
            return a.position.x < b.position.x
        end
        return a.position.y < b.position.y
    end)

    local focused = hl.get_active_monitor()
    for index, monitor in ipairs(monitors) do
        hl.dispatch(hl.dsp.focus({monitor = monitor.name}))
        hl.dispatch(hl.dsp.focus({workspace = index, on_current_monitor = true}))
    end
    if focused then
        hl.dispatch(hl.dsp.focus({monitor = focused.name}))
    end
end

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
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
        "dbus-update-activation-environment --systemd --all",
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
        "noctalia --daemon",
        "udiskie --no-automount --smart-tray",
        home .. "/.local/bin/power-mode.sh auto",
        "playerctl daemon",
    }
    for _, command in ipairs(commands) do
        hl.exec_cmd(command)
    end
    hl.timer(number_workspaces_by_monitor, {timeout = 500, type = "oneshot"})
end)

hl.on("monitor.added", function()
    -- a new output reports 0x0 until it is arranged, so number it a beat later
    hl.timer(number_workspaces_by_monitor, {timeout = 500, type = "oneshot"})
end)
hl.on("monitor.removed", number_workspaces_by_monitor)

-- Load shared Hyprland configuration (layouts, theme, rules, common binds)
local common = require("common")
common.setup()

-- laptop panel is less legible than the desktop monitors, so keep windows near opaque
hl.config({
    decoration = {
        active_opacity = 1.0,
        inactive_opacity = 0.90,
    },
})

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
