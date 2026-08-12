# Jellyfin playback stutter triage: Transcode Killer, HLS segments, NFS cache

Use this reference when Jellyfin is slow/stuttering and Semyon asks whether it is network/frontend, software config, or hardware.

## Fast diagnosis pattern

1. Check container state and host pressure:
   - `docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -i jellyfin`
   - `docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}' | grep -i jellyfin`
   - `findmnt /mnt/media; df -h /mnt/media /; uptime; mpstat 1 3 || top -b -n1 | head -30`
2. Inspect playback/transcode log signatures:
   - `docker logs --since 12h jellyfin 2>&1 | grep -E 'TranscodeKiller|cannot serve .*transcodes|TranscodeManager: /usr/lib/jellyfin-ffmpeg|StartPlaybackTimer : play_method'`
   - Count the damage:
     ```bash
     docker logs --since 12h jellyfin 2>&1 | awk '
       /TranscodeKiller/{tk++}
       /cannot serve .*transcodes/{miss++}
       /TranscodeManager: \/usr\/lib\/jellyfin-ffmpeg/{ff++}
       /StartPlaybackTimer : play_method/{pm[$NF]++}
       END{print "TranscodeKiller kills="tk+0; print "Missing HLS segment warnings="miss+0; print "FFmpeg jobs="ff+0; for (k in pm) print "play_method", k, pm[k]}'
     ```
3. Check config files:
   - `/mnt/media/docker_data/jellyfin/config/config/encoding.xml`
   - `/mnt/media/docker_data/jellyfin/config/plugins/configurations/Jellyfin.Plugin.TranscodeKiller.xml`
   - compose labels reveal source stack: `docker inspect jellyfin --format '{{json .Config.Labels}}' | jq .`
4. Benchmark media/cache I/O read-only/temporary:
   - Media read from inside Jellyfin: `docker exec jellyfin sh -lc 'dd if="/arrs/...file.mkv" of=/dev/null bs=8M count=64 iflag=direct status=progress'`
   - Cache write test: `docker exec jellyfin sh -lc 'dd if=/dev/zero of=/cache/transcodes/.hermes-test bs=8M count=64 oflag=direct status=progress; rm -f /cache/transcodes/.hermes-test'`
   - Clean up any `.hermes-test` file even if interrupted.

## Interpretation

If logs show repeated:

```text
Jellyfin.Plugin.TranscodeKiller: Killing transcode process
DynamicHlsController: cannot serve /cache/transcodes/...ts as it doesn't exist and no transcode is running
```

then the dominant issue is not generic network/frontend slowness. Jellyfin is creating HLS/remux/transcode segments, a plugin kills ffmpeg, and the client then requests missing segments. That produces stutter/retry loops even if CPU, NAS read speed, and LAN are acceptable.

Transcode Killer defaults/limits can be hostile to 4K. A config like:

```xml
<MaxWidth>1920</MaxWidth>
<MaxHeight>1080</MaxHeight>
```

can kill 2160p sessions or remux jobs. Disable/remove Transcode Killer first, or reconfigure it so it does not kill expected 4K playback.

## Common durable fixes

- Disable/remove Transcode Killer before blaming hardware.
- Put Jellyfin transcode temp/cache on local SSD, not `/mnt/media` NFS. NFS is fine for media libraries; it is a poor target for high-churn transcode segment writes.
- Enable segment deletion in `encoding.xml`; otherwise `/cache/transcodes` can accumulate tens of GB of stale HLS chunks.
- Enable hardware acceleration when devices are visible. Verify with:
  - host: `lspci | grep -Ei 'vga|3d|display'; nvidia-smi || true; ls -l /dev/dri`
  - container: `docker exec jellyfin sh -lc 'ls -l /dev/dri /dev/nvidia* 2>/dev/null; /usr/lib/jellyfin-ffmpeg/ffmpeg -hide_banner -hwaccels; /usr/lib/jellyfin-ffmpeg/ffmpeg -hide_banner -encoders 2>/dev/null | grep -E "nvenc|qsv|vaapi"'`
- Treat hardware/network upgrades as second-order until config is sane and the same title has been retested.

## Reporting guidance

Lead with a blunt classification:

- `not primarily network/frontend` when HLS segments are missing because a plugin killed ffmpeg.
- `software/config first` when CPU/iowait are fine and logs show Transcode Killer/HLS failures.
- Mention hardware only after noting whether HW acceleration is disabled/misconfigured and whether the cache is on NFS.

Do not restart or change Jellyfin automatically unless Semyon asked for repair, because it is a live media service. Offer the scoped repair and verification plan: disable/reconfigure Transcode Killer, move cache to local SSD, restart Jellyfin, then watch logs during playback of the same file.
