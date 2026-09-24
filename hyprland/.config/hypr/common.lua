-- Hyprland common Lua configuration module
-- Shared across all desktop / laptop machines running Hyprland 0.56+

local M = {}

local home = os.getenv("HOME")
local scripts = home .. "/.local/share/bin"

function M.exec(command)
    return hl.dsp.exec_cmd(command)
end

function M.move_active_window(direction, x, y)
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

function M.apply_noctalia_theme(load_generated_theme)
    local loaded, noctalia = pcall(load_generated_theme)
    if loaded and type(noctalia) == "table" and type(noctalia.apply_theme) == "function" then
        noctalia.apply_theme()
        return
    end

    -- Preserve the checked-in legacy palette on a clean deployment before
    -- Noctalia has generated ~/.config/hypr/noctalia.lua.
    hl.config({
        general = {
            col = {
                active_border = "rgb(89b4fa)",
                inactive_border = "rgb(1e1e2e)",
            },
        },
        group = {
            col = {
                border_active = "rgb(b4befe)",
                border_inactive = "rgb(1e1e2e)",
                border_locked_active = "rgb(f38ba8)",
                border_locked_inactive = "rgb(1e1e2e)",
            },
            groupbar = {
                col = {
                    active = "rgb(b4befe)",
                    inactive = "rgb(1e1e2e)",
                    locked_active = "rgb(f38ba8)",
                    locked_inactive = "rgb(1e1e2e)",
                },
                text_color = "rgb(1e1e2e)",
                text_color_inactive = "rgb(cdd6f4)",
                text_color_locked_active = "rgb(1e1e2e)",
                text_color_locked_inactive = "rgb(cdd6f4)",
            },
        },
    })
end

function M.setup(options)
    options = options or {}
    local legacy_shell_binds = options.legacy_shell_binds ~= false

    -- Environment variables
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

    -- Core configuration
    hl.config({
        input = {
            kb_layout = "us",
            kb_variant = "altgr-intl",
            kb_model = "pc105",
            kb_rules = "evdev",
            follow_mouse = 1,
            sensitivity = 0,
            force_no_accel = true,
            numlock_by_default = true,
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
    })

    hl.device({
        name = "epic mouse V1",
        sensitivity = -0.5,
    })

    -- Theming
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 20")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 20")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface font-name 'Cantarell 10'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface document-font-name 'Cantarell 10'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface monospace-font-name 'CaskaydiaCove Nerd Font Mono 9'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface font-hinting 'full'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface icon-theme 'Tela-circle-dracula'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'Catppuccin-Mocha'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")

    -- Animation curves and rules
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

    -- Window and Layer rules
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

    -- Keybindings
    local main = "SUPER"
    local term = "kitty"
    local file_manager = "nemo"
    local browser = "helium-browser"

    -- Window & Session management
    hl.bind(main .. " + SHIFT + P", M.exec("hyprpicker -a"))
    hl.bind(main .. " + Q", M.exec(scripts .. "/dontkillsteam.sh"))
    hl.bind("ALT + F4", M.exec(scripts .. "/dontkillsteam.sh"))
    hl.bind(main .. " + Delete", hl.dsp.exit())
    hl.bind(main .. " + W", hl.dsp.window.float({action = "toggle"}))
    hl.bind(main .. " + G", hl.dsp.group.toggle())
    hl.bind("ALT + Return", hl.dsp.window.fullscreen({action = "toggle"}))
    hl.bind(main .. " + L", M.exec(home .. "/.local/bin/noctalia-lock"))
    hl.bind(main .. " + SHIFT + F", M.exec(scripts .. "/windowpin.sh"))
    hl.bind(main .. " + Backspace", M.exec(scripts .. "/logoutlaunch.sh"))
    if legacy_shell_binds then
        hl.bind("CTRL + ALT + W", M.exec("killall waybar || (env reload_flag=1 " .. scripts .. "/wbarconfgen.sh)"))
    end

    -- Core applications
    hl.bind(main .. " + T", M.exec(term))
    hl.bind(main .. " + E", M.exec(file_manager))
    hl.bind(main .. " + B", M.exec(browser))
    hl.bind(main .. " + Space", M.exec("vicinae toggle"))
    hl.bind(main .. " + O", M.exec("obsidian"))
    hl.bind(main .. " + V", M.exec(home .. "/.local/bin/yank --palette"))
    hl.bind(main .. " + SHIFT + V", M.exec(home .. "/.local/bin/yank --palette"))
    hl.bind("CTRL + SHIFT + Space", M.exec(home .. "/.local/bin/yank --palette"))
    hl.bind("CTRL + SHIFT + 2", hl.dsp.global("com.t3tools.T3Code:capture-window"))
    hl.bind(main .. " + C", M.exec(home .. "/.local/bin/t3code-nightly"))

    -- Launcher menus
    hl.bind("CTRL + SHIFT + Escape", M.exec(scripts .. "/sysmonlaunch.sh"))
    if legacy_shell_binds then
        hl.bind(main .. " + A", M.exec("pkill -x rofi || " .. scripts .. "/rofilaunch.sh d"))
        hl.bind(main .. " + Tab", M.exec("pkill -x rofi || " .. scripts .. "/rofilaunch.sh w"))
        hl.bind(main .. " + SHIFT + E", M.exec("pkill -x rofi || " .. scripts .. "/rofilaunch.sh f"))
    end

    -- Audio controls
    local audio = scripts .. "/audio-control.sh"
    hl.bind("F10", M.exec(audio .. " mute"), {locked = true})
    hl.bind("F11", M.exec(audio .. " down"), {locked = true, repeating = true})
    hl.bind("F12", M.exec(audio .. " up"), {locked = true, repeating = true})
    hl.bind("XF86AudioMute", M.exec(audio .. " mute"), {locked = true})
    hl.bind("XF86AudioMicMute", M.exec(scripts .. "/volumecontrol.sh -i m"), {locked = true})
    hl.bind("XF86AudioLowerVolume", M.exec(audio .. " down"), {locked = true, repeating = true})
    hl.bind("XF86AudioRaiseVolume", M.exec(audio .. " up"), {locked = true, repeating = true})

    -- Media controls
    hl.bind("XF86AudioPlay", M.exec("playerctl play-pause"), {locked = true})
    hl.bind("XF86AudioPause", M.exec("playerctl play-pause"), {locked = true})
    hl.bind("XF86AudioNext", M.exec("playerctl next"), {locked = true})
    hl.bind("XF86AudioPrev", M.exec("playerctl previous"), {locked = true})

    -- Brightness controls
    hl.bind("XF86MonBrightnessUp", M.exec(home .. "/Scripts/brightness-all.sh i"), {locked = true, repeating = true})
    hl.bind("XF86MonBrightnessDown", M.exec(home .. "/Scripts/brightness-all.sh d"), {locked = true, repeating = true})

    -- Groups
    hl.bind(main .. " + CTRL + H", hl.dsp.group.prev())
    hl.bind(main .. " + CTRL + L", hl.dsp.group.next())

    -- Screenshots
    hl.bind(main .. " + P", M.exec(scripts .. "/screenshot.sh s"))
    hl.bind(main .. " + CTRL + P", M.exec(scripts .. "/screenshot.sh sf"))
    hl.bind(main .. " + ALT + P", M.exec(scripts .. "/screenshot.sh m"))
    hl.bind("Print", M.exec(scripts .. "/screenshot.sh p"))

    -- Script utilities
    hl.bind(main .. " + ALT + G", M.exec(scripts .. "/gamemode.sh"))
    hl.bind(main .. " + K", M.exec(scripts .. "/keyboardswitch.sh"))
    hl.bind(main .. " + slash", M.exec("pkill -x rofi || " .. scripts .. "/keybinds_hint.sh c"))

    local legacy_script_binds = {
        {main .. " + ALT + Right", scripts .. "/hyprpaper-cycle.sh next"},
        {main .. " + ALT + Left", scripts .. "/hyprpaper-cycle.sh prev"},
        {main .. " + ALT + Up", scripts .. "/wbarconfgen.sh n"},
        {main .. " + ALT + Down", scripts .. "/wbarconfgen.sh p"},
        {main .. " + SHIFT + R", "pkill -x rofi || " .. scripts .. "/wallbashtoggle.sh -m"},
        {main .. " + SHIFT + T", "pkill -x rofi || " .. scripts .. "/themeselect.sh"},
        {main .. " + SHIFT + A", "pkill -x rofi || " .. scripts .. "/rofiselect.sh"},
        {main .. " + SHIFT + X", "pkill -x rofi || " .. scripts .. "/themestyle.sh"},
        {main .. " + SHIFT + W", "pkill -x rofi || " .. scripts .. "/hyprpaper-cycle.sh select"},
        {main .. " + ALT + A", "pkill -x rofi || " .. scripts .. "/animations.sh"},
    }
    if legacy_shell_binds then
        for _, binding in ipairs(legacy_script_binds) do
            hl.bind(binding[1], M.exec(binding[2]))
        end
    end

    -- Focus navigation
    hl.bind(main .. " + Left", hl.dsp.focus({direction = "left"}))
    hl.bind(main .. " + Right", hl.dsp.focus({direction = "right"}))
    hl.bind(main .. " + Up", hl.dsp.focus({direction = "up"}))
    hl.bind(main .. " + Down", hl.dsp.focus({direction = "down"}))
    hl.bind("ALT + Tab", hl.dsp.focus({direction = "down"}))

    -- Workspaces 1..10
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

    -- Window resizing
    hl.bind(main .. " + SHIFT + Right", hl.dsp.window.resize({x = 30, y = 0, relative = true}), {repeating = true})
    hl.bind(main .. " + SHIFT + Left", hl.dsp.window.resize({x = -30, y = 0, relative = true}), {repeating = true})
    hl.bind(main .. " + SHIFT + Up", hl.dsp.window.resize({x = 0, y = -30, relative = true}), {repeating = true})
    hl.bind(main .. " + SHIFT + Down", hl.dsp.window.resize({x = 0, y = 30, relative = true}), {repeating = true})

    -- Window moving (floating vs tiled)
    hl.bind(main .. " + SHIFT + CTRL + Left", M.move_active_window("left", -30, 0), {
        repeating = true, description = "Move active window left",
    })
    hl.bind(main .. " + SHIFT + CTRL + Right", M.move_active_window("right", 30, 0), {
        repeating = true, description = "Move active window right",
    })
    hl.bind(main .. " + SHIFT + CTRL + Up", M.move_active_window("up", 0, -30), {
        repeating = true, description = "Move active window up",
    })
    hl.bind(main .. " + SHIFT + CTRL + Down", M.move_active_window("down", 0, 30), {
        repeating = true, description = "Move active window down",
    })

    -- Mouse and Special workspace
    hl.bind(main .. " + mouse_down", hl.dsp.focus({workspace = "e+1"}))
    hl.bind(main .. " + mouse_up", hl.dsp.focus({workspace = "e-1"}))
    hl.bind(main .. " + mouse:272", hl.dsp.window.drag(), {mouse = true})
    hl.bind(main .. " + mouse:273", hl.dsp.window.resize(), {mouse = true})
    hl.bind(main .. " + Z", hl.dsp.window.drag(), {mouse = true})
    hl.bind(main .. " + X", hl.dsp.window.resize(), {mouse = true})
    hl.bind(main .. " + ALT + S", hl.dsp.window.move({workspace = "special", follow = false}))
    hl.bind(main .. " + S", hl.dsp.workspace.toggle_special(""))
    hl.bind(main .. " + J", hl.dsp.layout("togglesplit"))
end

return M
