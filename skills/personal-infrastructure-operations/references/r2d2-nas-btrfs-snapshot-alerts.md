# R2D2 alerts during NAS Btrfs snapshot windows

Use this reference when R2D2 reports `/mnt/media disk check failed or timed out`, high load, and multiple Docker containers temporarily unhealthy around the same early-morning window.

## Pattern seen

A recurring alert around ~04:00 can look like:

```text
R2D2 watchdog alert:
- /mnt/media disk check failed or timed out:
- system load high: 15m load 18.57 on 12 CPUs
- unhealthy Docker containers: pihole, jellyfin, vaultwarden, immich_postgres
```

If the system later recovers without restarts, treat this first as a **NAS-side storage/NFS pressure event**, not as four independent Docker failures.

## Verification sequence

On the server:

```bash
# current state
timeout 5s findmnt -rn /mnt/media
timeout 8s df -hT /mnt/media
docker ps --filter health=unhealthy --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'
docker ps --format '{{.Names}}\t{{.Status}}' | egrep 'pihole|jellyfin|vaultwarden|immich_postgres|immich'

# historical load/iowait around the alert
sar -q -s 03:30:00 -e 05:30:00
sar -u -s 03:30:00 -e 05:30:00
sar -b -s 03:30:00 -e 05:30:00

# R2D2 evidence
base="$HOME/.hermes/cron/output/<r2d2-job-id>"
ls -t "$base" | head
```

On the NAS (`10.0.0.6`), read-only where possible:

```bash
ssh semyon@10.0.0.6 'hostname; date -Is; uptime; crontab -l 2>/dev/null || true'
ssh semyon@10.0.0.6 'for f in /etc/crontab /etc/cron.d/*; do echo ---$f; sed -n "1,200p" "$f" 2>/dev/null; done'
ssh semyon@10.0.0.6 'tail -160 /var/log/btrfs_snapshots.log 2>/dev/null || true'
```

Look especially for overlapping NAS cron jobs like:

```cron
0 4 * * * root /usr/local/bin/btrfs_snapshot_users.sh >> /var/log/btrfs_snapshots.log 2>&1
10 4 * * * root /usr/local/bin/btrfs_snapshot_all.sh >> /var/log/btrfs_snapshots.log 2>&1
```

The key evidence is a simultaneous server-side iowait/load spike plus NAS snapshot create/delete logs continuing through the alert window. Docker healthchecks for NFS-touching or latency-sensitive containers may fail temporarily while the NAS is busy.

## Durable fix

Do not restart containers if they are already healthy and the mount is clean; that only treats smoke. The durable fix is to prevent NAS snapshot jobs from overlapping and lower their I/O priority.

With NAS root approval/access, change `/etc/cron.d/btrfs-snapshots` to use a shared lock and staggered schedule:

```cron
0 4 * * * root flock -n /run/btrfs-snapshots.lock ionice -c2 -n7 nice -n 10 /usr/local/bin/btrfs_snapshot_users.sh >> /var/log/btrfs_snapshots.log 2>&1
45 4 * * * root flock -n /run/btrfs-snapshots.lock ionice -c2 -n7 nice -n 10 /usr/local/bin/btrfs_snapshot_all.sh >> /var/log/btrfs_snapshots.log 2>&1
```

If editing with root is not available, report that the live services are healthy and that NAS root is needed for the durable cron change.

## Reporting

Lead with current health first:

- `/mnt/media` mounted and df status
- current load
- unhealthy Docker count
- fresh R2D2 run status, if triggered

Then state the likely root cause as “NAS Btrfs snapshot/NFS pressure around 04:00” with sysstat and NAS log evidence. Avoid implying that pihole/Jellyfin/Vaultwarden/Immich each need separate repair unless they remain unhealthy after the snapshot window.
