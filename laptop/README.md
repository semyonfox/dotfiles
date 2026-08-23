# Laptop profile

CachyOS laptop overlay for mobile Hyprland behavior and the Noctalia shell layer.

Deploy with:

```bash
stow --no-folding home claude hyprland waybar swaync rofi laptop
```

This package owns host-specific Hyprland and Waybar files:

- `~/.config/dotfiles/machine-profile`
- `~/.config/hypr/hypridle.conf`
- `~/.config/hypr/monitors.conf`
- `~/.config/hypr/monitors.json`
- `~/.config/hypr/userprefs.conf`
- `~/.config/waybar/config.jsonc`

It also owns the laptop Noctalia sources:

- `~/.config/noctalia/`
- `~/.local/bin/noctalia-lock`
- `~/.local/bin/noctalia-idle-suspend`

Hyprland remains the compositor. Noctalia owns the shell surfaces on the laptop, while the old shell tools stay available for rollback. See [the changeover handover](../docs/noctalia-laptop-changeover-handover.md).
