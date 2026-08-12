# Restic endpoints to NAS: readiness and rollout

Use for Semyon's PC/laptop backups to the NAS when deciding scope, transport, and safe retention.

## Architecture

- NAS-local repository storage on Btrfs:
  - `/mnt/storage/users/semyon/backups/restic/pc`
  - `/mnt/storage/users/semyon/backups/restic/laptop`
- `rest-server --append-only`, bound only to trusted LAN/Tailscale interfaces.
- Endpoint jobs create snapshots only. A distinct NAS-local maintenance identity performs `restic check`, `forget --prune`, and repair actions.
- Do not use `/mnt/media` as `RESTIC_REPOSITORY`. In particular, a `soft` NFS mount with short timeout/retry settings can turn a transient transport event into a write error.
- NAS Btrfs snapshots must be explicitly verified for the repository's containing subvolume. They are a local rollback layer, not an independent/off-site backup.

## Readiness checks

1. On NAS: identify the true Btrfs subvolume for the repository, snapshot schedule/retention, free capacity, `btrfs device stats`, and scrub status.
2. On each endpoint: confirm OS/package manager, `restic version`, home filesystem capacity, Tailscale/LAN reachability, and expected user/systemd timer behavior.
3. Never call an offline device broken or protected. Mark it `Unknown` until live inspection plus a real snapshot and restore drill pass.

## Scope discovery

Use a bounded, read-only inventory of `$HOME` limited to its filesystem (`du -x`). Inspect large children of `~/.local/share` and `~/.config` individually rather than backing up or excluding these roots wholesale.

Usually include:

- user work: code, Git metadata, notes, documents, selected original/export media;
- state needed to rebuild: dotfiles, `~/.config`, selected `~/.local/share`, SSH/GPG state where encrypted-backup policy approves it;
- agent/session state: `.hermes`, `.t3`, `.claude`, `.codex` (retain SQLite `-wal`/`-shm` alongside databases);
- compact system recovery metadata separately: `/etc`, package manifest, systemd overrides, disk/mount metadata.

Usually exclude:

- trash, browser/download/package caches, `node_modules`, language dependency caches, build output;
- game installations/launch runtimes and other easily reproducible binaries;
- NAS-origin media or mounted shares (never back NAS data up to the same NAS path).

Review explicitly rather than guessing:

- old agent/T3 recovery bundles: preservation value can be high, but they may duplicate active state or NAS archives;
- editor state such as Zed/Cursor and browser profiles: can contain both valuable user state and large/rebuildable cache;
- Heroic/Prism/Steam: save/config data differs from re-downloadable installs.

## First rollout

1. Native-package install restic (on CachyOS/Arch: `sudo pacman -S --needed restic`).
2. Configure encrypted credentials in a `0600` local file plus password manager; never command line, chat, Git, or repository directory.
3. Create an initial small include list and explicit excludes. Dry-run and review paths/sizes.
4. Create first snapshot, confirm device/host tags, and perform a disposable targeted restore.
5. Add daily/AC-aware systemd timer only after the restore passes. Stagger it away from NAS Btrfs snapshot maintenance.
6. Expand scope after observing actual restic dedupe and NAS capacity.

## Maintenance and alerting

- Weekly metadata `restic check`; monthly sampled data read; quarterly full read/restore drill.
- Retention baseline: daily 14, weekly 8, monthly 12; tune only from observed repository growth.
- Alert for stale PC backup (>48h), stale laptop backup (>7d), failed checks, Btrfs errors, rest-server failures, and low pool space. Do not alert merely because a laptop is asleep/offline.
- During an incident, preserve logs and restore to a disposable path. Do not run `prune`, `rebuild-index`, or deletion until the diagnosis is established.
