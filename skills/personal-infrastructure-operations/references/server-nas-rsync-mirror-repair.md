# Server-to-NAS rsync recovery-mirror repair

Use when Semyon's `server-nas-backup.service` has failed or its NAS mirror lacks its completion marker.

## Safety invariant

The mirror at `/mnt/media/users/semyon/backups/server/current/` is valid **only** if it contains both a fresh `COMPLETE` marker and `MANIFEST.tsv`. A failed run deliberately removes `COMPLETE`; do not describe the data as a verified backup until a later run recreates it.

## Diagnosis

1. Confirm the NFS mount and inspect the service status:
   ```bash
   findmnt -T /mnt/media -n -o FSTYPE,SOURCE,OPTIONS
   systemctl --user status server-nas-backup.service --no-pager -n 30
   ```
2. Read the current boot journal and retain only actual rsync errors, not progress lines:
   ```bash
   journalctl --user -u server-nas-backup.service -b -o cat --no-pager \
     | grep '^rsync: \[sender\]' | sort -u
   ```
3. Inspect the executable via `readlink -f ~/.local/bin/server-nas-backup`. It is stowed from the dotfiles repository, so patch the resolved repo file—not a copied path.

## Correct remediation

- Do **not** add `--ignore-errors` merely to get a green service: it can allow an incomplete tree to look successful.
- Exclude only the precise unreadable/rebuildable live paths from the generic user-level mirror.
- Back up database state using the relevant application's consistent export/dump, not a live PostgreSQL/SQLite file copy.
- Validate with `bash -n`, `systemctl --user daemon-reload`, `systemctl --user reset-failed ...`, then start one controlled run.
- During the run, require zero new rsync permission errors. At completion verify `COMPLETE`, `MANIFEST.tsv`, systemd success, and a recent log.

## Known layout-specific examples

Container-owned PostgreSQL directories and locked runtime files may be unreadable to the user service. In the current server layout, precise exclusions were needed for:

```text
server-stacks/data/resolve/postgres/
server-stacks/data/pi-hole/etc-pihole/logrotate
```

Keep the surrounding Compose/config tree in the mirror. This is an example, not a blanket exclusion for every future stack.

## Restic UX note

Restic is encrypted/deduplicated storage, but it is not a restore-all black box. Operators can inspect snapshots with `snapshots`, locate paths with `find`/`ls`, browse them read-only with `restic mount`, restore selected files with `restore --include`, or extract a single file with `dump`. Keep an ordinary rsync recovery mirror for quick local disaster recovery and use restic for versioned/offsite protection.
