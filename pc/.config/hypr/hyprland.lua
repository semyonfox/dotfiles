-- Hyprland Lua configuration.
-- Migrated from the legacy hyprlang .conf files for Hyprland 0.56.

local home = os.getenv("HOME")
local scripts = home .. "/.local/share/bin"

local function exec(command)
    return hl.dsp.exec_cmd(command)
end

-- Outputs. Keep the AOC at 0x0 so portals and RustDesk treat it as primary.
hl.monitor({
    output = "desc:AOC CU34G2XP 1Q1S4HA000685",
    mode = "3440x1440@180.00",
    position = "0x0",
    scale = 1,
    bitdepth = 10,
    cm = "srgb",
})
hl.monitor({
    output = "desc:Microstep MSI G241 0x000002A7",
    mode = "1920x1080@60.00",
    position = "3440x0",
    scale = 1,
    cm = "srgb",
})
hl.workspace_rule({
    workspace = "1",
    monitor = "desc:AOC CU34G2XP 1Q1S4HA000685",
    default = true,
})
hl.workspace_rule({
    workspace = "2",
    monitor = "desc:Microstep MSI G241 0x000002A7",
    default = true,
})
hl.monitor({
    output = "",
    mode = "preferred",
    position = "5360x0",
    scale = 1,
})

-- Programs started once with the Hyprland session.
hl.on("hyprland.start", function()
    local commands = {
        scripts .. "/resetxdgportal.sh",
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
        "dbus-update-activation-environment --systemd --all",
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
        "systemctl --user restart vicinae.service", -- start launcher after Wayland env is imported
        scripts .. "/polkitkdeauth.sh",
        "sh -lc 'systemctl --user --quiet is-active waybar.service || pgrep -x waybar >/dev/null || { command -v waybar >/dev/null && waybar; }'",
        "blueman-applet",
        "udiskie --no-automount --smart-tray",
        "nm-applet --indicator",
        "sh -lc 'systemctl --user --quiet is-active swaync.service || pgrep -x swaync >/dev/null || { command -v swaync >/dev/null && swaync; }'",
        scripts .. "/hyprpaper-cycle.sh current",
        "sh -lc 'compgen -G /sys/class/power_supply/BAT\\* >/dev/null && [ -x \"$HOME/.local/share/bin/batterynotify.sh\" ] && \"$HOME/.local/share/bin/batterynotify.sh\"'",
        home .. "/.local/bin/power-mode.sh auto",
        "hypridle",
        "playerctl daemon",
    }
    for _, command in ipairs(commands) do
        hl.exec_cmd(command)
    end
end)

hl.env("PATH", os.getenv("PATH") .. ":" .. scripts)
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("GDK_SCALE", "1")
hl.env("PROTON_LOG", "0")
hl.env("WINE_CPU_TOPOLOGY", "4:2")
hl.env("STAGING_SHARED_MEMORY", "1")
hl.env("STEAM_RUNTIME_LAUNCH_DEBUG", "0")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("TERMINAL", "kitty")

hl.config({
    input = {
        kb_layout = "us",
        kb_model = "pc105",
        kb_rules = "evdev",
        follow_mouse = 1,
        sensitivity = 0,
        force_no_accel = true,
        numlock_by_default = true,
        touchpad = {
            natural_scroll = true,
        },
    },
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
    misc = {
        vrr = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
    },
    xwayland = {
        force_zero_scaling = true,
    },
    general = {
        gaps_in = 3,
        gaps_out = 8,
        border_size = 2,
        col = {
            active_border = {
                colors = {"rgba(ca9ee6ff)", "rgba(f2d5cfff)"},
                angle = 45,
            },
            inactive_border = {
                colors = {"rgba(b4befecc)", "rgba(6c7086cc)"},
                angle = 45,
            },
        },
        layout = "dwindle",
        resize_on_border = true,
    },
    group = {
        col = {
            border_active = {
                colors = {"rgba(ca9ee6ff)", "rgba(f2d5cfff)"},
                angle = 45,
            },
            border_inactive = {
                colors = {"rgba(b4befecc)", "rgba(6c7086cc)"},
                angle = 45,
            },
            border_locked_active = {
                colors = {"rgba(ca9ee6ff)", "rgba(f2d5cfff)"},
                angle = 45,
            },
            border_locked_inactive = {
                colors = {"rgba(b4befecc)", "rgba(6c7086cc)"},
                angle = 45,
            },
        },
    },
    decoration = {
        rounding = 10,
        active_opacity = 0.95,
        inactive_opacity = 0.80,
        fullscreen_opacity = 1.0,
        dim_inactive = true,
        dim_strength = 0.08,
        dim_special = 0.3,
        shadow = {
            enabled = false,
        },
        blur = {
            enabled = true,
            size = 6,
            passes = 3,
            new_optimizations = true,
            ignore_opacity = true,
            xray = false,
            special = true,
        },
    },
    render = {
        cm_enabled = true,
        cm_auto_hdr = 1,
        send_content_type = true,
        use_fp16 = 2,
        keep_unmodified_copy = 2,
    },
})

hl.device({
    name = "epic mouse V1",
    sensitivity = -0.5,
})

-- Cursor, GTK theme, icons, and fonts. These intentionally run on reload too.
hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 20")
hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice'")
hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 20")
hl.exec_cmd("gsettings set org.gnome.desktop.interface font-name 'Segoe UI 10'")
hl.exec_cmd("gsettings set org.gnome.desktop.interface document-font-name 'Segoe UI 10'")
hl.exec_cmd("gsettings set org.gnome.desktop.interface monospace-font-name 'Segoe UI 10'")
hl.exec_cmd("gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'")
hl.exec_cmd("gsettings set org.gnome.desktop.interface font-hinting 'full'")
hl.exec_cmd("gsettings set org.gnome.desktop.interface icon-theme 'Tela-circle-dracula'")
hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'Catppuccin-Mocha'")
hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")

-- Animation defaults plus the PC-specific snappier overrides.
hl.curve("wind", {type = "bezier", points = {{0.05, 0.9}, {0.1, 1.05}}})
hl.curve("winIn", {type = "bezier", points = {{0.1, 1.1}, {0.1, 1.1}}})
hl.curve("winOut", {type = "bezier", points = {{0.3, -0.3}, {0, 1}}})
hl.curve("liner", {type = "bezier", points = {{1, 1}, {1, 1}}})
hl.curve("snap", {type = "bezier", points = {{0.25, 1}, {0.5, 1}}})
hl.curve("pop", {type = "bezier", points = {{0.34, 1.56}, {0.64, 1}}})
hl.animation({leaf = "windows", enabled = true, speed = 3, bezier = "pop"})
hl.animation({leaf = "windowsIn", enabled = true, speed = 6, bezier = "winIn", style = "slide"})
hl.animation({leaf = "windowsOut", enabled = true, speed = 3, bezier = "snap", style = "popin 90%"})
hl.animation({leaf = "windowsMove", enabled = true, speed = 5, bezier = "wind", style = "slide"})
hl.animation({leaf = "border", enabled = true, speed = 1, bezier = "liner"})
hl.animation({leaf = "borderangle", enabled = true, speed = 30, bezier = "liner", style = "once"})
hl.animation({leaf = "fade", enabled = true, speed = 3, bezier = "snap"})
hl.animation({leaf = "workspaces", enabled = true, speed = 3, bezier = "snap", style = "slide"})
hl.animation({leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "wind", style = "slidevert"})

-- Window and layer rules.
hl.window_rule({
    name = "opaque-media-and-terminal",
    match = {
        class = "(kitty|mpv|vlc|imv|firefox|chromium|Brave-browser|zen|okular)",
    },
    opacity = "1.0 override",
})
hl.layer_rule({
    name = "blur-rofi",
    match = {namespace = "rofi"},
    blur = true,
})
hl.layer_rule({
    name = "blur-notifications",
    match = {namespace = "notifications"},
    blur = true,
})
hl.layer_rule({
    name = "vicinae-style",
    match = {namespace = "vicinae"},
    blur = true,
    ignore_alpha = 0,
    no_anim = true,
})

-- Key bindings.
local main = "SUPER"
local term = "kitty"
local file_manager = "nemo"
local browser = "helium-browser"

hl.bind(main .. " + SHIFT + P", exec("hyprpicker -a"))
hl.bind(main .. " + Q", exec(scripts .. "/dontkillsteam.sh"))
hl.bind("ALT + F4", exec(scripts .. "/dontkillsteam.sh"))
hl.bind(main .. " + Delete", hl.dsp.exit())
hl.bind(main .. " + W", hl.dsp.window.float({action = "toggle"}))
hl.bind(main .. " + G", hl.dsp.group.toggle())
hl.bind("ALT + Return", hl.dsp.window.fullscreen({action = "toggle"}))
hl.bind(main .. " + L", exec(scripts .. "/hyprlock-wrapper"))
hl.bind(main .. " + SHIFT + F", exec(scripts .. "/windowpin.sh"))
hl.bind(main .. " + Backspace", exec(scripts .. "/logoutlaunch.sh"))
hl.bind("CTRL + ALT + W", exec("killall waybar || (env reload_flag=1 " .. scripts .. "/wbarconfgen.sh)"))

hl.bind(main .. " + T", exec(term))
hl.bind(main .. " + E", exec(file_manager))
hl.bind(main .. " + B", exec(browser))
hl.bind("CTRL + SHIFT + Escape", exec(scripts .. "/sysmonlaunch.sh"))
hl.bind(main .. " + A", exec("pkill -x rofi || " .. scripts .. "/rofilaunch.sh d"))
hl.bind(main .. " + Tab", exec("pkill -x rofi || " .. scripts .. "/rofilaunch.sh w"))
hl.bind(main .. " + SHIFT + E", exec("pkill -x rofi || " .. scripts .. "/rofilaunch.sh f"))

local audio = home .. "/.config/waybar/scripts/audio-control.sh"
hl.bind("F10", exec(audio .. " mute && pkill -RTMIN+9 waybar"), {locked = true})
hl.bind("F11", exec(audio .. " down && pkill -RTMIN+9 waybar"), {locked = true, repeating = true})
hl.bind("F12", exec(audio .. " up && pkill -RTMIN+9 waybar"), {locked = true, repeating = true})
hl.bind("XF86AudioMute", exec(audio .. " mute && pkill -RTMIN+9 waybar"), {locked = true})
hl.bind("XF86AudioMicMute", exec(scripts .. "/volumecontrol.sh -i m"), {locked = true})
hl.bind("XF86AudioLowerVolume", exec(audio .. " down && pkill -RTMIN+9 waybar"), {locked = true, repeating = true})
hl.bind("XF86AudioRaiseVolume", exec(audio .. " up && pkill -RTMIN+9 waybar"), {locked = true, repeating = true})
hl.bind("XF86AudioPlay", exec("playerctl play-pause"), {locked = true})
hl.bind("XF86AudioPause", exec("playerctl play-pause"), {locked = true})
hl.bind("XF86AudioNext", exec("playerctl next"), {locked = true})
hl.bind("XF86AudioPrev", exec("playerctl previous"), {locked = true})
hl.bind("XF86MonBrightnessUp", exec(home .. "/Scripts/brightness-all.sh i"), {locked = true, repeating = true})
hl.bind("XF86MonBrightnessDown", exec(home .. "/Scripts/brightness-all.sh d"), {locked = true, repeating = true})

hl.bind(main .. " + CTRL + H", hl.dsp.group.prev())
hl.bind(main .. " + CTRL + L", hl.dsp.group.next())
hl.bind(main .. " + P", exec(scripts .. "/screenshot.sh s"))
hl.bind(main .. " + CTRL + P", exec(scripts .. "/screenshot.sh sf"))
hl.bind(main .. " + ALT + P", exec(scripts .. "/screenshot.sh m"))
hl.bind("Print", exec(scripts .. "/screenshot.sh p"))

local script_binds = {
    {main .. " + ALT + G", scripts .. "/gamemode.sh"},
    {main .. " + ALT + Right", scripts .. "/hyprpaper-cycle.sh next"},
    {main .. " + ALT + Left", scripts .. "/hyprpaper-cycle.sh prev"},
    {main .. " + ALT + Up", scripts .. "/wbarconfgen.sh n"},
    {main .. " + ALT + Down", scripts .. "/wbarconfgen.sh p"},
    {main .. " + SHIFT + R", "pkill -x rofi || " .. scripts .. "/wallbashtoggle.sh -m"},
    {main .. " + SHIFT + T", "pkill -x rofi || " .. scripts .. "/themeselect.sh"},
    {main .. " + SHIFT + A", "pkill -x rofi || " .. scripts .. "/rofiselect.sh"},
    {main .. " + SHIFT + X", "pkill -x rofi || " .. scripts .. "/themestyle.sh"},
    {main .. " + SHIFT + W", "pkill -x rofi || " .. scripts .. "/hyprpaper-cycle.sh select"},
    {main .. " + K", scripts .. "/keyboardswitch.sh"},
    {main .. " + slash", "pkill -x rofi || " .. scripts .. "/keybinds_hint.sh c"},
    {main .. " + ALT + A", "pkill -x rofi || " .. scripts .. "/animations.sh"},
}
for _, binding in ipairs(script_binds) do
    hl.bind(binding[1], exec(binding[2]))
end

hl.bind(main .. " + Left", hl.dsp.focus({direction = "left"}))
hl.bind(main .. " + Right", hl.dsp.focus({direction = "right"}))
hl.bind(main .. " + Up", hl.dsp.focus({direction = "up"}))
hl.bind(main .. " + Down", hl.dsp.focus({direction = "down"}))
hl.bind("ALT + Tab", hl.dsp.focus({direction = "down"}))

for workspace = 1, 10 do
    local key = workspace % 10
    hl.bind(main .. " + " .. key, hl.dsp.focus({workspace = workspace}))
    hl.bind(main .. " + SHIFT + " .. key, hl.dsp.window.move({workspace = workspace}))
    hl.bind(main .. " + ALT + " .. key, hl.dsp.window.move({workspace = workspace, silent = true}))
end
hl.bind(main .. " + CTRL + Right", hl.dsp.focus({workspace = "r+1"}))
hl.bind(main .. " + CTRL + Left", hl.dsp.focus({workspace = "r-1"}))
hl.bind(main .. " + CTRL + Down", hl.dsp.focus({workspace = "empty"}))
hl.bind(main .. " + CTRL + ALT + Right", hl.dsp.window.move({workspace = "r+1"}))
hl.bind(main .. " + CTRL + ALT + Left", hl.dsp.window.move({workspace = "r-1"}))

hl.bind(main .. " + SHIFT + Right", hl.dsp.window.resize({x = 30, y = 0, relative = true}), {repeating = true})
hl.bind(main .. " + SHIFT + Left", hl.dsp.window.resize({x = -30, y = 0, relative = true}), {repeating = true})
hl.bind(main .. " + SHIFT + Up", hl.dsp.window.resize({x = 0, y = -30, relative = true}), {repeating = true})
hl.bind(main .. " + SHIFT + Down", hl.dsp.window.resize({x = 0, y = 30, relative = true}), {repeating = true})

local function move_active_window(direction, x, y)
    return function()
        local window = hl.get_active_window()
        if not window then
            return
        end
        if window.floating then
            hl.dispatch(hl.dsp.window.move({x = x, y = y, relative = true}))
        else
            hl.dispatch(hl.dsp.window.move({direction = direction}))
        end
    end
end

hl.bind(main .. " + SHIFT + CTRL + Left", move_active_window("left", -30, 0), {
    repeating = true, description = "Move active window left",
})
hl.bind(main .. " + SHIFT + CTRL + Right", move_active_window("right", 30, 0), {
    repeating = true, description = "Move active window right",
})
hl.bind(main .. " + SHIFT + CTRL + Up", move_active_window("up", 0, -30), {
    repeating = true, description = "Move active window up",
})
hl.bind(main .. " + SHIFT + CTRL + Down", move_active_window("down", 0, 30), {
    repeating = true, description = "Move active window down",
})

hl.bind(main .. " + mouse_down", hl.dsp.focus({workspace = "e+1"}))
hl.bind(main .. " + mouse_up", hl.dsp.focus({workspace = "e-1"}))
hl.bind(main .. " + mouse:272", hl.dsp.window.drag(), {mouse = true})
hl.bind(main .. " + mouse:273", hl.dsp.window.resize(), {mouse = true})
hl.bind(main .. " + Z", hl.dsp.window.drag(), {mouse = true})
hl.bind(main .. " + X", hl.dsp.window.resize(), {mouse = true})
hl.bind(main .. " + ALT + S", hl.dsp.window.move({workspace = "special", follow = false}))
hl.bind(main .. " + S", hl.dsp.workspace.toggle_special(""))
hl.bind(main .. " + J", hl.dsp.layout("togglesplit"))

-- PC-specific power profiles and application launchers.
hl.bind(main .. " + F10", exec(home .. "/.local/bin/power-mode.sh saver"))
hl.bind(main .. " + F11", exec(home .. "/.local/bin/power-mode.sh ac"))
hl.bind(main .. " + F12", exec(home .. "/.local/bin/power-mode.sh beast"))
hl.bind(main .. " + SHIFT + F12", exec(home .. "/.local/bin/power-mode.sh cycle"))
hl.bind(main .. " + Space", exec("/usr/bin/vicinae toggle"))
hl.bind(main .. " + O", exec("obsidian"))
hl.bind(main .. " + V", exec(home .. "/.local/bin/yank --palette"))
hl.bind(main .. " + SHIFT + V", exec(home .. "/.local/bin/yank --palette"))
hl.bind("CTRL + SHIFT + Space", exec(home .. "/.local/bin/yank --palette"))
hl.bind(main .. " + C", exec(home .. "/.local/bin/t3code-nightly"))

-- Generated by the theme and animation selectors. These load last so a
-- user-selected profile can override the stable defaults above.
require("./overrides/theme")
require("./overrides/animation")
