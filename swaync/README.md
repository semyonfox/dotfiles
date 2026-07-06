# SwayNC package

Shared Sway Notification Center config and Catppuccin-style theme for Hyprland desktops.

Deploy with the desktop profile:

```bash
stow --no-folding home claude hyprland waybar swaync rofi pc
stow --no-folding home claude hyprland waybar swaync rofi laptop
```

This package owns:

- `~/.config/swaync/config.json`
- `~/.config/swaync/style.css`

The config notifies Waybar through `~/.config/waybar/scripts/swaync.sh receive`, so deploy `waybar` with this package.

Useful commands:

```bash
swaync &
swaync-client -op -sw
swaync-client --count
```
