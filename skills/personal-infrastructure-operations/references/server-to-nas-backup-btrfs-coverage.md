# Server-to-NAS backup and Btrfs coverage assessment

Use this when protecting server code, AI-agent history, credentials, and homelab recovery state under Semyon's NAS user directory, then deciding what existing Btrfs snapshots already cover.

## Discovery sequence

1. On the server, verify `/mnt/media` is the real NFS mount with `findmnt -T /mnt/media`; refuse to write if it fell back to a local directory.
2. Inventory irreplaceable user state before copying:
   - code and Git metadata: `~/code`, `~/projects`, `~/obsidian`, `~/dotfiles`
   - AI state: `~/.claude`, `~/.codex`, `~/.hermes`, `~/.t3`, `~/.cursor`
   - deployment/config roots: `~/server-stacks`, user systemd units, SSH/cloud CLI configuration, and readable host recovery configuration
3. Preserve session databases and Git metadata. Exclude only clearly rebuildable trees such as `node_modules`, virtual environments, build output, and disposable caches.
4. Write timestamped snapshots with `COMPLETE`, a manifest, logs, restore documentation, and a `latest` symlink. Do not publish `latest` until the copy and manifest finish.
5. Inspect the NAS directly over SSH (`nas`, normally `10.0.0.6`) against `/mnt/storage`, not through the NFS client, for Btrfs subvolumes, snapshot schedules, device health, scrub results, and destination coverage.

## Btrfs coverage reasoning

- Determine whether the backup destination is inside an existing source subvolume. If `/mnt/storage/users/semyon` is a subvolume, everything under `users/semyon/backups/server` is already covered by snapshots of that parent user subvolume.
- Inner rsync/hard-link recovery points plus outer Btrfs snapshots are layered retention, not automatically wasteful duplication. The inner layer provides explicit server recovery points; the outer layer protects them from NAS-side deletion or damage. Copy-on-write and hard links reduce physical duplication.
- Do not assume an existing narrow backup such as `backups/server-stacks-config` covers code, Git objects, AI histories, credentials, T3/Hermes state, or host inventories. Compare actual source lists.
- Align schedules so the server copy normally completes before the NAS takes its parent-subvolume snapshot. A Btrfs snapshot taken during the first large copy may contain a partial unpublished tree; `COMPLETE` and `latest` distinguish valid recovery points.
- Btrfs snapshots on the same pool are not an off-site backup. RAID10 plus local snapshots protects against many disk failures and accidental changes, but not theft, fire, controller-wide loss, malicious root deletion, or total pool loss. Recommend encrypted independent/off-site protection for the irreplaceable subset rather than the media library.

## NAS verification commands

Run read-only checks first, using sudo only where Btrfs requires it:

```bash
btrfs filesystem usage -T /mnt/storage
btrfs subvolume list -t /mnt/storage
btrfs device stats /mnt/storage
btrfs scrub status /mnt/storage
crontab -l
cat /etc/cron.d/btrfs-snapshots
systemctl status cron --no-pager
```

Also inspect snapshot scripts and `/var/log/btrfs_snapshots.log`. Compare current cron configuration with historical log timestamps before declaring duplicate jobs: logs can show old schedules that were already corrected. Search `/etc`, cron spool, and OpenMediaVault state for additional active invocations if current logs suggest overlap.

## Live-copy verification

- Large NFS copies can look stalled from client-side `du`. Inspect destination growth and newest file timestamps directly on the NAS before intervening.
- Check for concurrent NAS writers and snapshot maintenance before blaming Btrfs or restarting services.
- Treat the backup as incomplete until the destination contains `COMPLETE` and `latest` resolves to that completed snapshot.
- For SQLite-heavy AI state, preserve DB, WAL, and SHM files together and test integrity before any restore over live state. Stop the owning service for a definitive restore or application-consistent export.
