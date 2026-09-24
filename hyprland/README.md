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
- shared scripts under `~/.local/share/bin`

Host overlays own:

- `~/.config/hypr/hyprland.lua`
- `~/.config/hypr/hypridle.conf`
- `~/.config/hypr/monitors.conf`
- `~/.config/hypr/monitors.json`
- `~/.config/hypr/userprefs.conf`
- PC-only `~/.config/hypr/xdph.conf`

That split keeps monitor layout, idle/suspend behavior, HDR/RustDesk capture, and launcher preferences out of the shared package.

Hyprland 0.56+ uses the host `hyprland.lua` entrypoint and shared `common.lua` module. The `.conf` compositor tree remains only as rollback/reference state; Hypridle, Hyprlock, Hyprpaper, and XDPH continue using their own upstream-supported config formats. Noctalia generates `~/.config/hypr/noctalia.lua` as runtime theme state, so it is deliberately not tracked.

Useful commands:

```bash
hyprctl reload
hyprctl monitors
~/.local/share/bin/hyprpaper-cycle.sh next
```
