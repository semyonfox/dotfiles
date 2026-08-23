# Laptop Noctalia changeover

The laptop keeps Hyprland for compositor, monitor, input, window, and keybind duties. Noctalia owns the shell layer.

## Current state

- Work is on the local `laptop-noctalia` branch and is not committed or pushed.
- Noctalia owns the bar, launcher, notifications, wallpaper, lock screen, idle behavior, tray, and normal system widgets.
- Legacy tools remain installed for rollback and must not be removed until the laptop passes daily use tests.

## Ownership

- Hyprland owns monitors, window management, input, rules, and compositor keybinds.
- Noctalia configuration lives in `hyprland/.config/noctalia/` and is shared by every GUI host.
- Laptop helpers live in `laptop/.local/bin/`.

## Deploy

```bash
stow --no-folding -R laptop
```

The laptop profile still deploys the shared desktop packages. Laptop-specific guards prevent legacy shell services from starting when Noctalia is installed.

## Validation

```bash
noctalia config validate "$HOME/dotfiles/hyprland/.config/noctalia"
git diff --check
```

## Rollback

Restore the old shell autostarts and the prior `SUPER+L` binding in `laptop/.config/hypr/userprefs.conf`. Keep Hyprland installed throughout the experiment.

## Known limits

- Noctalia renders fingerprint and password status beside the native input, not inside it.
- Dynamic quote text is not a native lockscreen widget feature and is intentionally not used.
- The lock helper attempts a scoped fprintd restart when the one-time sudo rule exists, then always locks through Noctalia.
