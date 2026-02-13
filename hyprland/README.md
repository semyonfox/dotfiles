# Hyprland Configuration

Based on HyDE (HyprDots) with Catppuccin Mocha theme.

This is a fully functional Hyprland configuration using the HyDE framework as a starting point. The configuration has been customized and is now maintained as a standalone stow package for portability and version control.

## Deployment

### Prerequisites

Ensure stow is installed:
```bash
sudo pacman -S stow  # arch/cachyos
sudo apt install stow  # ubuntu/debian
sudo dnf install stow  # fedora
```

### Deploy This Package

From the dotfiles directory:
```bash
cd ~/dotfiles
stow hyprland
```

This creates symlinks from ~/.config/hypr/ to the configuration files in this package.

Verify deployment:
```bash
ls -la ~/.config/hypr/
# should show symlinks pointing to ~/dotfiles/hyprland/.config/hypr/
```

### Deploy with Related Packages

Deploy hyprland along with waybar (status bar):
```bash
cd ~/dotfiles
stow hyprland waybar
```

Or include shell configs:
```bash
cd ~/dotfiles
stow home hyprland waybar
```

### Remove This Package

To remove the symlinks:
```bash
cd ~/dotfiles
stow -D hyprland
```

## Credits

HyDE (HyprDots) - Hyprland dots framework and theme
Repository: https://github.com/prasanthrangan/hyprdots
Theme: Catppuccin Mocha

## Configuration Structure

```
.config/hypr/
├── hyprland.conf           # Main configuration (sources other files)
├── animations.conf         # Animation settings
├── keybindings.conf        # All keybindings
├── windowrules.conf        # Window-specific rules
├── monitors.conf           # Display/monitor configuration
├── userprefs.conf          # User preferences (for customization)
├── animations/             # Animation preset files
└── themes/
    ├── common.conf         # Shared theme settings
    ├── theme.conf          # Active theme (Catppuccin Mocha)
    └── colors.conf         # Color overrides
```

## Components

- **Launcher**: Rofi (configured in HyDE style)
- **Bar**: Waybar (dynamically generated, see `waybar/` package)
- **Notifications**: Mako (Omarchy-themed via symlink)
- **Wallpaper**: SWWW daemon
- **Terminal**: Default XDG terminal (configured via other packages)

## Quick Start

After deploying with stow, Hyprland will auto-reload on configuration changes. No restart needed for most edits.

### Key Keybindings

- `SUPER + Return` - Open terminal
- `SUPER + Space` - Open Rofi launcher
- `SUPER + Q` - Kill active window
- `SUPER + F` - Fullscreen
- `SUPER + T` - Tile mode toggle

(See `keybindings.conf` for full list)

## Customization

### Edit Configuration Files

All config files are in `~/.config/hypr/` after deployment. Changes take effect immediately.

### User Preferences

Add personal customizations to `userprefs.conf` to avoid modifying the base configs.

### Regenerate Waybar

If you need to regenerate waybar configuration (from HyDE scripts):

```bash
# If HyDE is installed
cd ~/HyDE
./Scripts/wbarconfgen.sh
```

## Updating Theme

To change Hyprland theme colors or appearance, edit files in `~/.config/hypr/themes/` after deployment.

## Integration with Omarchy

The mako notification daemon configuration is symlinked from Omarchy's theme system:

```
~/.config/mako/config → ~/.config/omarchy/current/theme/mako.ini
```

This allows themes to control notification appearance through Omarchy's theme management system. This is intentional and separates concerns between window manager (Hyprland) and notification styling (Omarchy).

## Reverting to Defaults

If configuration becomes broken:

```bash
# Restore from dotfiles
cd ~/dotfiles
stow -D hyprland
stow hyprland

# Or reset individual configs
cp ~/.config/hypr/hyprland.conf.backup ~/.config/hypr/hyprland.conf
```

## Related Packages

- `waybar/` - Status bar configuration
- `home/` - Shell configuration
