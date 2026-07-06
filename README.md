# semyon's dotfiles

Public GNU Stow dotfiles for a small mixed fleet: Ubuntu headless server, CachyOS desktop PC, CachyOS laptop, and minimal/NAS-style installs.

Each top-level directory is a Stow package that mirrors `$HOME`. Shared packages stay generic; machine-specific deviations live in host overlays.

## Quick Start

```bash
git clone git@github.com:semyonfox/dotfiles.git ~/dotfiles
cd ~/dotfiles

./setup.sh --dry-run
./setup.sh
```

`setup.sh` detects the host name and deploys the matching profile. You can also be explicit:

```bash
./setup.sh --profile server
./setup.sh --profile pc
./setup.sh --profile laptop
./setup.sh --packages "home claude"
```

Manual Stow commands are still fine:

```bash
stow --no-folding home claude server
stow --no-folding home claude hyprland waybar swaync rofi pc
stow --no-folding home claude hyprland waybar swaync rofi laptop
```

## Package Model

| Package | Purpose |
| --- | --- |
| `home` | Shared shell, git, tmux, terminal, Neovim, Starship, and user bin helpers |
| `claude` | Tracked Claude global guidance files |
| `hyprland` | Shared Hyprland config: keybindings, theme, scripts, window rules |
| `waybar` | Shared Waybar scripts and styling |
| `swaync` | Shared notification center config and styling |
| `rofi` | Shared Rofi menu/theme files |
| `server` | Ubuntu/headless server overlay and T3 Code user service |
| `pc` | Desktop monitor, Waybar layout, RustDesk XDPH picker, and GPU notes |
| `laptop` | Mobile monitor, idle, and Waybar layout |

Profiles:

| Profile | Packages |
| --- | --- |
| `server` | `home claude server` |
| `pc` | `home claude hyprland waybar swaync rofi pc` |
| `laptop` | `home claude hyprland waybar swaync rofi laptop` |
| `nas` / `minimal` | `home claude` |

## Important Layout Rules

- Shared files go in shared packages only when they work on every target that deploys them.
- Machine-specific files go in `server/`, `pc/`, or `laptop/`.
- `hyprland` deliberately does not own `monitors.conf`, `monitors.json`, `hypridle.conf`, or `userprefs.conf`; host overlays own those.
- `waybar` deliberately does not own `config.jsonc`; host overlays own the layout while the shared package owns scripts and CSS.
- Claude and Codex config stay separate. This repo tracks Claude guidance under `claude/`; it does not install Codex global Fable routing.

## Public Safety

This repo is public. Do not commit secrets, private keys, credentials, tokens, local service env files, browser stores, or generated auth/cache directories.

Tracked examples may use placeholders only. See [docs/public-safety.md](docs/public-safety.md).

## Useful Commands

```bash
./setup.sh --dry-run --profile pc
./setup.sh --profile server

stow --no-folding -n -v home claude
stow --no-folding -D hyprland waybar swaync rofi pc

./install-deps.sh
./install.sh
./switch-to-zsh.sh
```

## Notes

- Host packages install `~/.config/dotfiles/machine-profile`; shared helpers read it when behavior differs by device.
- Server T3 Code is managed by `server/.config/systemd/user/t3-code-headless.service`.
- PC and laptop desktop configs assume the shared `home`, `hyprland`, `waybar`, `swaync`, and `rofi` packages are deployed with the host overlay.
