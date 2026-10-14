# Hyprland package

Shared Hyprland configuration for the PC and laptop.

Deploy it with a host overlay:

```bash
stow --no-folding home claude hyprland noctalia pc
stow --no-folding home claude hyprland noctalia laptop
```

The shared package owns:

- `~/.config/hypr/common.lua`
- `~/.config/hypr/hyprland.conf`
- keybindings, animations, window rules, and theme files
- lock screen text/config files
- the few remaining shared scripts under `~/.local/share/bin` (`audio-control.sh`, `gamemode.sh`)

Host overlays own:

- `~/.config/hypr/hyprland.lua`
- `~/.config/hypr/hypridle.conf`
- `~/.config/hypr/monitors.conf`
- `~/.config/hypr/monitors.json`
- `~/.config/hypr/userprefs.conf`
- PC-only `~/.config/hypr/xdph.conf`

That split keeps monitor layout, idle/suspend behavior, HDR/RustDesk capture, and launcher preferences out of the shared package.

Hyprland 0.56+ uses the host `hyprland.lua` entrypoint and shared `common.lua` module. The `.conf` compositor tree is deprecated and kept for reference only; Hypridle, Hyprlock, Hyprpaper, and XDPH continue using their own upstream-supported config formats. Noctalia generates `~/.config/hypr/noctalia.lua` as runtime theme state, so it is deliberately not tracked.

Useful commands:

```bash
hyprctl reload
hyprctl monitors
noctalia msg wallpaper-next
```

## Deprecated

HyDE was retired on 2026-10-14. Its scripts in `~/.local/share/bin`, `~/.config/hyde`, dunst, mako and wlogout were archived to the NAS (`users/semyon/backups/laptop-hyde-20261014.tar.zst`) and removed from the laptop. The PC still has its local copies until it is cleaned up the same way.

Binds that used HyDE scripts now go through Noctalia or native Hyprland:

| Bind | Was | Now |
| --- | --- | --- |
| Super+Backspace | `logoutlaunch.sh` (wlogout) | `noctalia msg panel-toggle session` |
| Super+P, Super+Ctrl+P, Super+Alt+P, Print | `screenshot.sh` (grimblast + swappy) | `noctalia msg screenshot-region`, `screenshot-annotate`, `screenshot-fullscreen`, `screenshot-fullscreen all` |
| Super+K | `keyboardswitch.sh` | `noctalia msg keyboard-layout-cycle` |
| Super+Shift+F | `windowpin.sh` | Lua float + pin in `common.lua` |
| Ctrl+Shift+Escape | `sysmonlaunch.sh` | `kitty -e btop` toggle |
| Mic mute | `volumecontrol.sh -i m` | `noctalia msg mic-mute` |

Removed with no replacement: the `legacy_shell_binds` option and the rofi, waybar, wallbash, theme and animation selector binds, Super+/ (`keybinds_hint.sh`), and the `resetxdgportal.sh` startup hack. `hyprpaper-cycle.sh` is unbound because Noctalia owns wallpapers.
