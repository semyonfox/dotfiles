# NAS Btrfs snapshot refresh/prune and post-checks

Use for Semyon's NAS at `semyon@10.0.0.6`, where the real Btrfs filesystem is `/mnt/storage`. The main server's `/mnt/media` is only an NFS view; do not do Btrfs admin work there.

## Safe snapshot refresh/prune pattern

1. SSH to the NAS and verify target:
   - `hostname`
   - `findmnt /mnt/storage`
   - `sudo btrfs filesystem usage /mnt/storage`
   - `sudo btrfs subvolume list -o /mnt/storage | sed -n 's/.* path //p' | grep '^snapshots/'`
2. If the user asks how much space will be freed, capture before/after baselines. Without a before baseline, do not invent a delta.
   - `df -h /mnt/storage`
   - `sudo btrfs filesystem usage /mnt/storage`
3. Create fresh snapshots before deleting old ones:
   - `sudo /usr/local/bin/btrfs_snapshot_users.sh`
   - `sudo /usr/local/bin/btrfs_snapshot_all.sh`
4. Delete old snapshots as Btrfs subvolumes only:
   - never `rm -rf` snapshot directories
   - delete child/deeper snapshot subvolumes first if nested
   - use `sudo btrfs subvolume delete <snapshot-path>`
5. Verify final state using privileged Btrfs listing, not only `find`:
   - `sudo btrfs subvolume list -o /mnt/storage | sed -n 's/.* path //p' | grep '^snapshots/' | sort`

## D-state pitfall from this NAS

After a large snapshot prune, broad recursive cleanup like:

```bash
find /mnt/storage/snapshots -depth -type d -empty -delete
```

hung in uninterruptible D state on this NAS (`wait_current_trans`, `btrfs_get_dir_last_index`). If this happens:

- stop adding recursive filesystem pressure
- do not keep retrying `find`/deep `du`
- use `btrfs subvolume list` for snapshot verification
- wait for the transaction to clear or schedule a safe NAS reboot
- after it clears, run SMART/Btrfs checks rather than assuming disk failure

## Michelle subvolume finding

`/mnt/storage/users/michelle` is a valid Btrfs subvolume, not a regular-directory mistake:

- `Subvolume ID: 261`
- `Parent ID: 5`
- quota referenced/exclusive were effectively empty (`16 KiB` in the session)
- snapshot creation issue was the destination directory under `snapshots/users/michelle`, not the source subvolume

## Storage accounting pattern

For "what is using the storage?", prefer live datasets and avoid snapshot apparent sizes because Btrfs snapshots double-count shared extents with `du`.

Useful top-level probes:

```bash
for d in /mnt/storage/*; do
  [ -e "$d" ] || continue
  [ "$(basename "$d")" = snapshots ] && continue
  timeout 90s du -xsh "$d" 2>/dev/null || echo "TIMEOUT $d"
done | sort -h
```

Then drill into likely large areas with timeout-bounded `du`. In the observed session, the large live users were:

- `arrs` media library
- `users/semyon/videos`, especially OBS/PS4 recordings
- `backups/laptop`
- `users/adam/Transit`

Do not delete based on this audit alone; for media cleanup use the quarantine-first dedupe workflow in `references/nas-media-audit-dedupe.md`.

## SMART and Btrfs health checks after snapshot churn

Run these from the NAS, with sudo:

```bash
lsblk -o NAME,MODEL,SERIAL,SIZE,TYPE,MOUNTPOINTS
btrfs device stats /mnt/storage
for dev in /dev/sda /dev/sdb /dev/sdc /dev/sdd; do
  smartctl -H -A -l error -l selftest "$dev"
done
```

For a quick active check:

```bash
for dev in /dev/sda /dev/sdb /dev/sdc /dev/sdd; do
  smartctl -t short "$dev"
done
# wait the reported duration, then:
for dev in /dev/sda /dev/sdb /dev/sdc /dev/sdd; do
  smartctl -H -A -l selftest "$dev" | awk '/overall-health|Num  Test_Description|# 1|Reallocated_Sector_Ct|Current_Pending_Sector|Offline_Uncorrectable|UDMA_CRC_Error_Count|Reported_Uncorrect|Command_Timeout|Temperature_Celsius|Power_On_Hours/'
done
btrfs device stats /mnt/storage
ps -o pid,stat,wchan:32,cmd -p <suspect-pids> 2>/dev/null || true
```

Healthy result shape:

- SMART health `PASSED`
- latest short self-test `Completed without error`
- reallocated/pending/offline-uncorrectable/CRC/command-timeout counters zero
- Btrfs device stats all zero
- no remaining D-state snapshot processes
