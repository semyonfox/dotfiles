# NAS capacity read-only audit pattern

Use when Semyon asks whether `/mnt/media` or the NAS is overly used, what can be cleaned, or whether usage is normal. This is an inspection-only workflow unless he explicitly approves deletion.

## Safe read-only checks

```bash
# Capacity and mount identity
df -hT /mnt/media
findmnt -T /mnt/media -o TARGET,SOURCE,FSTYPE,OPTIONS

# Top-level usage visible through the NFS client
du -h --max-depth=1 /mnt/media 2>/tmp/nas-du-errors | sort -h
sed -n '1,80p' /tmp/nas-du-errors

# Common cleanup candidates, without deleting
find /mnt/media -xdev \
  \( -iname '*trash*' -o -iname '*recycle*' -o -iname '@Recycle' -o -iname '.Trash-*' -o -iname '*tmp*' -o -iname '*cache*' \) \
  -type d -prune -print 2>/tmp/nas-find-errors

# Media stack breakdown
du -h --max-depth=2 /mnt/media/arrs 2>/tmp/arrs-du-errors | sort -h | tail -50
du -h --max-depth=1 /mnt/media/docker_data 2>/tmp/dockerdata-du-errors | sort -h | tail -50

# Downloads candidates and hardlink status
find /mnt/media/arrs/downloads -type f -printf '%n\t%s\t%p\n' 2>/tmp/downloads-file-errors \
  | sort -k2,2nr | head -40 | numfmt --field=2 --to=iec-i --suffix=B
find /mnt/media/arrs/downloads -type f -printf '%n\n' 2>/dev/null | sort | uniq -c | sort -nr
```

## Interpretation

- `df` is authoritative for total filesystem capacity, but `du` over `/mnt/media` may only account for what the NFS export exposes and what the current user can traverse.
- If `df` used space is much higher than client-side `du`, do **not** assume the difference is deletable from this host. Likely causes include NAS-side snapshots/datasets, hidden exports, permissions, or bind/loop quirks. Recommend checking directly on the NAS before cleanup.
- `arrs/downloads` is often the safest first review target, but do not delete based only on size. Check whether files are still seeding, wanted by qBittorrent, or hardlinked/imported by Sonarr/Radarr.
- Link count `1` in downloads means files are probably not hardlinked into the library; link count `>1` may mean deleting the download path only removes one directory entry and may not free full storage.
- Trash/tmp/cache directories can be listed safely, but deletion still needs user approval. Some app caches are harmless to clear, others may cause rebuilds or service churn.

## Reporting style

Report in this order:

1. `df` capacity summary and verdict: healthy / watch / urgent.
2. Visible top consumers by directory.
3. Obvious cleanup candidates with estimated reclaimable space.
4. Any `df` vs `du` mismatch and why it limits confidence.
5. Explicitly state that nothing was changed.

Avoid overclaiming from NFS client data when snapshots or export loops are visible.
