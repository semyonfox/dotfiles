# Laptop profile

CachyOS laptop overlay for mobile Hyprland behavior and the Noctalia shell layer.

Deploy with:

```bash
stow --no-folding home claude hyprland noctalia laptop
```

This package owns host-specific files:

- `~/.config/dotfiles/machine-profile`
- `~/.config/hypr/hyprland.lua`
- `~/.config/hypr/hypridle.conf`
- `~/.config/hypr/monitors.conf`
- `~/.config/hypr/monitors.json`
- `~/.config/hypr/userprefs.conf`

Shared Noctalia config and helpers come from the `hyprland`, `noctalia`, and `home` packages.

Noctalia maps its standard power profiles onto the laptop helper's tuning:

- `performance` selects Beast.
- `balanced` selects AC or Mobile based on the current power source.
- `power-saver` selects Saver.

Hyprland remains the compositor and Noctalia owns the shell surfaces. The retired waybar/swaync/rofi stack lives on the `legacy-shell-stack` branch. See [the changeover handover](../docs/noctalia-laptop-changeover-handover.md).

The Lua entrypoint disables the retired HyDE/Rofi/Waybar/Wallbash selector bindings. Their `.conf` targets remain for rollback, but they do not control the live Lua compositor. Noctalia's generated `~/.config/hypr/noctalia.lua` owns the final palette, with the previous checked-in palette used as a boot-safe fallback.
