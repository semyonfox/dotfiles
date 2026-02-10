local wezterm = require("wezterm")
local config = wezterm.config_builder() -- improved way to load config

-- Shared settings (apply to all OSs)
config.adjust_window_size_when_changing_font_size = false
config.color_scheme = "Tokyo Night Moon"
config.enable_tab_bar = false

config.font_size = 12.0
config.window_background_opacity = 0.95
config.window_decorations = "NONE"

-- Keybindings
config.keys = {
    { key = "q", mods = "CTRL", action = wezterm.action.ToggleFullScreen },
    { key = "'", mods = "CTRL", action = wezterm.action.ClearScrollback("ScrollbackAndViewport") },
}
config.mouse_bindings = {
    { event = { Up = { streak = 1, button = "Left" } }, mods = "CTRL", action = wezterm.action.OpenLinkAtMouseCursor },
}

-- Platform-specific settings
--if wezterm.target_triple:find("windows") then
    -- WINDOWS ONLY: Use WSL by default
    --config.default_domain = "WSL:archlinux" -- Change "Arch" to your actual distro name if different
    -- config.font = wezterm.font("JetBrainsMonoNL-Regular")
    -- Optional: Windows-specific backdrop (since kde_window_background_blur doesn't work here)
    -- config.win32_system_backdrop = "Acrylic" 
--elseif wezterm.target_triple:find("linux") then
    -- LINUX ONLY (e.g. your Arch install)
    --config.kde_window_background_blur = true
    -- config.font = wezterm.font("JetBrainsMono Nerd Font Mono")
--end

return config
