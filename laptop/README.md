# Laptop profile

CachyOS laptop overlay for mobile Hyprland behavior and the Noctalia shell layer.

Deploy with:

```bash
stow --no-folding home claude hyprland noctalia laptop
```

This package owns host-specific files:
- `~/.config/dotfiles/machine-profile`
- `~/.config/hypr/hyprland.lua`
- `~/.config/noctalia/idle.toml`
- `~/.config/noctalia/lockscreen-login.toml`
- `~/.config/dotfiles/fprintd-sleep.service`, a system unit installed once by hand (see the file)
- `~/.config/dotfiles/power-mode-write`, the root helper `power-mode.sh` calls through a NOPASSWD sudo rule, installed by hand to `/usr/local/bin` (see the file)
- `~/.local/bin/cpu-power` and `~/.local/bin/cpu-bench`, set the cpu's sustained power limit and benchmark it
- `~/.local/bin/zenity`, closes `--progress --auto-close` dialogs on EOF, which zenity 4.2 never does and which left Steam stuck unpacking its runtime
- `~/.config/hypr/monitors.conf`
- `~/.config/hypr/monitors.json`
- `~/.config/hypr/userprefs.conf`
- `~/.local/bin/ddc-defaults.sh`, reapplies brightness and contrast 100/100 to the portable APT panel, which loses them on power loss

Shared Noctalia config and helpers come from the `hyprland`, `noctalia`, and `home` packages.

`power-mode.sh` uses Noctalia's three power profiles as its modes, and Super+F10/F11/F12 select them directly:

- `performance`: full tuning, cpu sustained power limit (PL1) 64 W. Drops to `balanced` when unplugged or at login on battery.
- `balanced`: follows the power source, AC tuning and 28 W when plugged in, battery tuning and 15 W when not.
- `power-saver`: lowest tuning and 15 W, kept across plugging and unplugging.

The firmware otherwise holds PL1 at 15 W.

Charge limits are separate from the power profiles. UPower owns them and the "Battery charging" toggle in Noctalia's control centre switches between stopping at 80% (resuming below 75%, from the `CHARGE_LIMIT` hwdb default) and charging to 100%. UPower remembers the choice across reboots.

Hyprland remains the compositor and Noctalia owns the shell surfaces. The retired waybar/swaync/rofi stack lives on the `legacy-shell-stack` branch. See [the changeover handover](../docs/noctalia-laptop-changeover-handover.md).

The retired HyDE/Rofi/Waybar/Wallbash bindings were removed from `common.lua` on 2026-10-14; see the deprecated section in [the hyprland package README](../hyprland/README.md). Noctalia's generated `~/.config/hypr/noctalia.lua` owns the final palette, with the previous checked-in palette used as a boot-safe fallback.
