# Laptop profile

CachyOS laptop overlay for mobile Hyprland behavior and the Noctalia shell layer.

Deploy with:

```bash
stow --no-folding home claude hyprland noctalia laptop
```

This package owns host-specific files:

- `~/.config/dotfiles/machine-profile`
- `~/.config/hypr/hypridle.conf`
- `~/.config/hypr/monitors.conf`
- `~/.config/hypr/monitors.json`
- `~/.config/hypr/userprefs.conf`

Shared Noctalia config and helpers come from the `hyprland`, `noctalia`, and `home` packages.

Hyprland remains the compositor and Noctalia owns the shell surfaces. The retired waybar/swaync/rofi stack lives on the `legacy-shell-stack` branch. See [the changeover handover](../docs/noctalia-laptop-changeover-handover.md).
