# Hyprland package

Shared Hyprland configuration for the PC and laptop.

Deploy it with a host overlay:

```bash
stow --no-folding home claude hyprland waybar swaync rofi pc
stow --no-folding home claude hyprland waybar swaync rofi laptop
```

The shared package owns:

- `~/.config/hypr/hyprland.conf`
- keybindings, animations, window rules, and theme files
- lock screen text/config files
- shared scripts under `~/.local/share/bin`

Host overlays own:

- `~/.config/hypr/hypridle.conf`
- `~/.config/hypr/monitors.conf`
- `~/.config/hypr/monitors.json`
- `~/.config/hypr/userprefs.conf`
- PC-only `~/.config/hypr/xdph.conf`

That split keeps monitor layout, idle/suspend behavior, HDR/RustDesk capture, and launcher preferences out of the shared package.

Useful commands:

```bash
hyprctl reload
hyprctl monitors
~/.local/share/bin/hyprpaper-cycle.sh next
```
