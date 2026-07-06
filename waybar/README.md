# Waybar package

Shared Waybar scripts, CSS, and theme colors for Hyprland desktops.

Deploy it with a host overlay:

```bash
stow --no-folding home claude hyprland waybar swaync rofi pc
stow --no-folding home claude hyprland waybar swaync rofi laptop
```

The shared package owns:

- `~/.config/waybar/style.css`
- `~/.config/waybar/theme.css`
- scripts for audio, VPN, battery, Wi-Fi marquee, Bluetooth marquee, and SwayNC status

Host overlays own:

- `~/.config/waybar/config.jsonc`

PC and laptop use different module layouts, but they call the same shared scripts and style sheet.

Restart Waybar after config changes:

```bash
pkill waybar
waybar &
```
