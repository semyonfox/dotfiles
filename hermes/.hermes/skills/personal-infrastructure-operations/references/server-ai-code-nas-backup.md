# Server AI/code backup to NAS

Use this pattern when a server is a single point of failure for source code, Git history, AI-agent conversations/state, and homelab configuration.

## Scope discovery

1. Verify the destination is the real NAS mount with `findmnt -T /mnt/media` and check capacity with timeout-bounded `df`.
2. Inventory source sizes before copying. Preserve AI state such as `.claude`, `.codex`, `.hermes`, `.t3`, and `.cursor`; session SQLite databases, WAL/SHM files, JSONL transcripts, memories, skills, and Git metadata are valuable training/recovery material.
3. Include code, notes, dotfiles, deployment/config roots, user systemd units, and sensitive recovery configuration. Generate readable host inventories for packages, mounts, disks, enabled services, and Docker containers/images.
4. Exclude only clearly rebuildable bulk: `node_modules`, virtual environments, compiler build trees, temporary agent sandboxes, disposable image/audio caches, and trace logs. Do not broadly exclude hidden directories or database sidecars.

## Snapshot layout

Keep one documented class-level backup root:

```text
<nas>/backups/<host>/
├── README.md
├── latest -> snapshots/<UTC timestamp>
├── logs/
└── snapshots/<UTC timestamp>/
    ├── COMPLETE
    ├── MANIFEST.tsv
    ├── home-<user>/
    └── system/
```

Use `rsync -aHAX --numeric-ids --relative`. On later runs, point `--link-dest` at the previous completed snapshot so unchanged files are hard-linked. Publish `latest` only after the copy, manifest, and verification complete. Retain a bounded number of completed snapshots; never prune incomplete snapshots as if they were valid.

## Safety and consistency

- Refuse to run unless the destination resolves to the expected NFS filesystem. This prevents a missing automount from filling the local root disk.
- Use `umask 077`, permission-restrict the backup root, and document that cloud/SSH credentials may be present.
- Serialize runs with `flock`.
- Active SQLite stores are not guaranteed consistent from a plain filesystem copy. For critical AI/service databases, prefer the SQLite backup API or stop/quiesce the owning service; otherwise retain DB plus WAL/SHM and explicitly mark the snapshot crash-consistent, then run `PRAGMA integrity_check` on restored copies before replacement.
- Avoid `--delete` against a shared destination. Deletion is acceptable only inside the new timestamped snapshot or during explicit retention pruning of completed snapshots.

## Automation

Install a low-priority user systemd oneshot plus persistent weekly timer. Keep the script in the stow-managed dotfiles package, dry-run Stow first, then daemon-reload and enable the timer. Add a recovery README both to dotfiles and the NAS backup root.

For a long initial copy, `systemctl start` may block until completion. Start it without a short command timeout or monitor the unit separately. `systemctl is-active --quiet` can return non-zero while a oneshot is still `activating`; monitor `systemctl show -p SubState --value` and wait while it is `start`. Do not report completion until `COMPLETE` exists and `latest` resolves to that snapshot.

## Verification

1. Require successful service exit and a `COMPLETE` marker.
2. Resolve and inspect `latest`.
3. Compare representative source/destination files by SHA-256 and compare counts/sizes for code and each AI-state root.
4. Confirm the manifest exists and contains transcript/session/database paths.
5. Validate copied critical SQLite databases on isolated restore copies.
6. Verify timer next-run state and review the backup log.
7. If the first copy is still running, report it as in progress and attach a monitored completion notification rather than claiming success.
