# Dotfiles and personal operations tooling

Personal Linux configuration and operational tooling managed with [GNU Stow](https://www.gnu.org/software/stow/). The repository composes shared shell and desktop configuration with host-specific overlays for a headless Ubuntu server and CachyOS desktop/laptop machines.

This is personal infrastructure work, not a general-purpose provisioning framework.

## What it demonstrates

- **Composable configuration:** shared packages plus `server`, `pc` and `laptop` profile overlays.
- **Safe Stow deployment:** dry runs, conflict detection, optional backups, rollback on failure and symlink verification.
- **Operational safeguards:** user-level systemd services with network ordering, restart limits, duplicate-process/port preflight checks and `flock` single-instance protection.
- **Workstation operations:** tracked rclone mount configuration and a hardware-specific AMD GPU profile script with capability checks.
- **Public-config hygiene:** runtime state, credentials and machine-specific secrets are excluded; checked-in environment examples use placeholders.

## Layout

| Package | Purpose |
| --- | --- |
| `home/` | shared shell, Git, terminal and developer configuration |
| `server/` | headless-server overlays and user services |
| `pc/` | desktop-specific configuration |
| `laptop/` | laptop-specific configuration |
| `claude/` | tracked agent configuration placeholders and guidance |
| `lib/` | shared installer helpers |

## Deploy safely

Preview first:

```bash
./setup.sh --dry-run --profile server
```

Then deploy an explicit profile:

```bash
./setup.sh --profile pc
```

`setup.sh` checks for non-symlink conflicts before changing files and can back them up before proceeding. Review [INSTALLATION.md](./INSTALLATION.md) and the package-level documentation before applying a profile to a new machine.

## Scope

Host-specific paths, service names, device identifiers and dependencies intentionally need adaptation outside this environment. The repository records configuration and safety practices for a small personal fleet; it does not claim production provisioning, fleet management or universal cross-platform support.
