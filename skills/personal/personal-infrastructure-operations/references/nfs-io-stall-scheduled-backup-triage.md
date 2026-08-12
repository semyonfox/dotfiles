# NFS I/O stall from scheduled backup triage

Use this when the server load average spikes but CPU is mostly idle, `/mnt/media` checks time out, and containers backed by the NAS/NFS mount briefly go unhealthy.

## Symptom pattern

- Load average high relative to 12 logical CPUs, but `sar -u`/`mpstat` shows low user+system CPU and high `%iowait`.
- `sar -q` shows blocked tasks during the window.
- Watchdog output may include:
  - `/mnt/media disk check failed or timed out`
  - high 15-minute load
  - NAS-backed containers unhealthy, often services with bind mounts under `/mnt/media` such as Jellyfin, Vaultwarden, Pi-hole, Immich/Postgres, Servarr apps.
- Subsequent watchdog runs can be silent once the NFS stall clears.

## Read-only investigation pattern

1. Confirm current pressure is not CPU saturation:
   - `uptime`
   - `mpstat 1 5` or `sar -u`
   - `cat /proc/pressure/cpu`
2. Compare historical load and iowait around the alert:
   - `sar -q -s HH:MM:SS -e HH:MM:SS`
   - `sar -u -s HH:MM:SS -e HH:MM:SS`
3. Read the watchdog run output under `~/.hermes/cron/output/<job_id>/...` and identify the first non-silent run.
4. Check system scheduling around the same minute:
   - `systemctl list-timers --all --no-pager`
   - `/etc/crontab`, `/etc/cron.d/*`, and user crontabs
   - `journalctl --since ... --until ...` filtered for `cron|timer|backup|nfs|docker|media|health`
5. Inspect Docker bind mounts to see which containers depend on `/mnt/media`:
   - `docker inspect --format '{{.Name}} {{range .Mounts}}{{.Source}} -> {{.Destination}}; {{end}}' $(docker ps -q) | grep /mnt/media`
6. Check candidate job logs for abnormal runtime and NFS-backed destinations.

## Known Semyon-server example

The Irish Rail backup cron runs hourly:

```text
/etc/cron.d/server-stacks-backups
0 * * * * semyon /home/semyon/server-stacks/backups/scripts/irish-rail-db-backup.sh hourly >> /home/semyon/server-stacks/backups/irish-rail-db-backup.cron.log 2>&1
```

The script streams a logical Postgres dump directly to:

```text
/mnt/media/backups/irish-rail/postgres/hourly
```

When that run takes far longer than surrounding hourly runs, it can line up with high iowait and NAS-backed container health flaps. Treat this as an NFS/NAS I/O stall unless CPU metrics prove otherwise.

## Safer remediation pattern

Do not immediately restart half the stack if the stall has cleared and containers are healthy again. Prefer reducing future NFS pressure:

1. Dump to local disk first, e.g. under `/home/semyon/server-stacks/data/backups/tmp/...`.
2. Verify the dump locally (`pg_restore --list`, non-empty files).
3. Transfer to `/mnt/media` after verification using `nice`/`ionice` and preferably `rsync` or a simple copy.
4. Consider moving the job off exact `:00` boundaries to avoid overlapping hourly timers, sysstat, app jobs, and other backups.
5. Keep watchdog probes timeout-bounded; an alert on a slow mount is better than a cron worker wedged in filesystem calls.

## Reporting style

Be explicit that high load from blocked I/O is not the same as CPU saturation. Give the probable chain: scheduled backup -> NFS write pressure/stall -> blocked tasks/iowait -> NAS-backed containers unhealthy -> recovery after the job/mount clears.