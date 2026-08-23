# Dotfiles and personal operations tooling

Personal Linux configuration and operational tooling managed with [GNU Stow](https://www.gnu.org/software/stow/). The repository composes shared shell and desktop configuration with host-specific overlays for a headless Ubuntu server and CachyOS desktop/laptop machines.

This is personal infrastructure work, not a general-purpose provisioning framework.

## What it demonstrates

- **Composable configuration:** shared packages plus `server`, `pc` and `laptop` profile overlays.
- **Safe Stow deployment:** dry runs, conflict detection, optional backups, rollback attempts after a backed-up conflict, and symlink verification.
- **Operational safeguards:** user-level systemd services with network ordering, restart limits, duplicate-process/port preflight checks and `flock` single-instance protection.
- **Workstation operations:** tracked rclone mount configuration and a hardware-specific AMD GPU profile script with capability checks.
- **Public-config hygiene:** runtime state, credentials and machine-specific secrets are excluded; checked-in environment examples use placeholders.

## Prerequisites

Clone this repository directly beneath the account whose home directory should receive the Stow links:

```bash
git clone git@github.com:semyonfox/dotfiles.git "$HOME/dotfiles"
cd "$HOME/dotfiles"
```

Install GNU Stow before running `setup.sh`. The script may attempt to install it with `sudo` even in dry-run mode, so install it deliberately first:

```bash
# Arch / CachyOS
sudo pacman -S stow

# Ubuntu / Debian
sudo apt update && sudo apt install -y stow

# Fedora
sudo dnf install -y stow

stow --version
```

## Profiles

| Profile | Stow packages |
| --- | --- |
| `server` | `home claude server` |
| `pc` | `home claude hyprland waybar swaync rofi pc` |
| `laptop` | `home claude hyprland waybar swaync rofi laptop` |
| `nas` / `minimal` | `home claude` |

Additional packages are opt-in. For example, `codex` is not part of a named profile:
`codex` is intentionally omitted from the default profiles. Deploy it explicitly
on devices where the same Codex global defaults and custom skills are wanted.

## Important Layout Rules

- Shared files go in shared packages only when they work on every target that deploys them.
- Machine-specific files go in `server/`, `pc/`, or `laptop/`.
- `hyprland` deliberately does not own `monitors.conf`, `monitors.json`, `hypridle.conf`, or `userprefs.conf`; host overlays own those.
- `waybar` deliberately does not own `config.jsonc`; host overlays own the layout while the shared package owns scripts and CSS.
- Claude and Codex config stay separate. This repo tracks Claude guidance under `claude/`; the optional `codex/` package tracks Codex defaults and skills only, with no Codex global Fable routing.

## Laptop Noctalia experiment

The laptop keeps Hyprland as compositor and uses Noctalia as its shell layer. The migration passed its daily-use gate and has landed for all hosts. See [the laptop Noctalia handover](docs/noctalia-laptop-changeover-handover.md) and [laptop package notes](laptop/README.md).

## Public Safety

This repo is public. Do not commit secrets, private keys, credentials, tokens, local service env files, browser stores, or generated auth/cache directories.

Tracked examples may use placeholders only. See [docs/public-safety.md](docs/public-safety.md).

## Useful Commands

```bash
./setup.sh --dry-run --packages codex
```

## Preview before deployment

```bash
./setup.sh --dry-run --profile server
./setup.sh --dry-run --profile pc
./setup.sh --dry-run --profile laptop
./setup.sh --dry-run --profile minimal
```

Read the output: the installer deliberately continues after the final simulated Stow invocation so a zero exit code alone is not a proof that Stow found no conflicts. For a strict non-interactive preview with Stow's exit status, run the matching package list directly:

```bash
stow --no-folding --simulate --verbose home claude hyprland waybar swaync rofi pc
```

## Deploy

After reviewing the preview:

```bash
./setup.sh --profile server
# or: ./setup.sh --profile pc
# or: ./setup.sh --profile laptop
```

If a target is an existing non-symlink file, the script asks whether to move it into a timestamped backup such as `$HOME/dotfiles_backup_YYYYMMDD_HHMMSS`. Answering anything other than `y` aborts before deployment.

The larger installers are intentionally separate and interactive:

```bash
./install-deps.sh  # package installation and optional downloads
./install.sh       # broader guided setup; may change shell configuration
```

## Verify and undo

The installer prints a symlink-verification count after deployment. You can inspect a representative link explicitly:

```bash
test -L "$HOME/.bashrc" &&
test "$(readlink -f "$HOME/.bashrc")" = "$HOME/dotfiles/home/.bashrc" &&
printf 'home package linked correctly\n'
```

To remove links, unstow the **same package list** used for deployment:

```bash
# Example: undo the PC profile links
stow --no-folding -D home claude hyprland waybar swaync rofi pc
```

Unstowing removes managed symlinks only. It does not uninstall packages, disable services or restore prior files. If the installer created a backup, restore it after unstowing:

```bash
cp -a "$HOME/dotfiles_backup_YYYYMMDD_HHMMSS"/. "$HOME"/
```

Automatic restoration is attempted only when the failed run created a backup.

## Optional server service

The server profile contains a host-specific T3 Code user service. Review its hard-coded paths, port and executable before enabling it; it is not a generic profile prerequisite.

```bash
systemctl --user daemon-reload
systemctl --user enable --now t3-code-headless.service
systemctl --user status t3-code-headless.service
journalctl --user -u t3-code-headless.service -n 50 --no-pager
```

Disable it deliberately with:

```bash
systemctl --user disable --now t3-code-headless.service
```

## Scope

Host-specific paths, service names, device identifiers and dependencies intentionally need adaptation outside this environment. The repository records configuration and safety practices for a small personal fleet; it does not claim production provisioning, fleet management or universal cross-platform support.
