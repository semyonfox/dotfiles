# Jellyfin LAN throughput and playback triage

Use this reference when Jellyfin playback stutters and the user suspects LAN congestion. Separate playback pipeline failures from actual client/network bottlenecks with measured evidence.

## Pattern from the 2026-07-08 Jellyfin incident

Two issues can coexist:

1. Jellyfin-side playback pipeline issue:
   - Logs showed `Jellyfin.Plugin.TranscodeKiller` repeatedly killing HLS/remux jobs.
   - Jellyfin then logged `DynamicHlsController: cannot serve /cache/transcodes/...ts as it doesn't exist and no transcode is running`.
   - Transcode temp/cache was on NFS and had accumulated tens of GB of stale transcodes.
   - Hardware acceleration was available but Jellyfin encoding config had `HardwareAccelerationType` set to `none`.
2. LAN client path issue:
   - Server↔NAS was acceptable, but PC↔everything had hundreds of ms latency, packet loss, and single-digit Mbit/s throughput despite the NIC reporting 1G full duplex.
   - The PC NIC was Realtek RTL8125 via `r8169`; EEE was enabled and active. This is a strong candidate before blaming Jellyfin, WAN, or the NAS.

## Read-only triage sequence

1. Inventory Jellyfin container and playback logs:
   - `docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -i jellyfin`
   - `docker stats --no-stream jellyfin`
   - `docker logs --since 2h --tail 300 jellyfin 2>&1 | grep -E 'TranscodeKiller|DynamicHlsController|TranscodeManager|StartPlaybackTimer|ffmpeg'`
   - Count kill/missing-segment events over 6–12h before drawing conclusions.
2. Inspect encoding and plugin config:
   - `/mnt/media/docker_data/jellyfin/config/config/encoding.xml`
   - `/mnt/media/docker_data/jellyfin/config/plugins/configurations/Jellyfin.Plugin.TranscodeKiller.xml`
   - Check whether transcode temp path is on local SSD or NFS.
3. Check server/NAS health:
   - `findmnt /mnt/media`, `df -h /mnt/media /`
   - `mpstat 1 3` or `top` for CPU/iowait
   - Read/write smoke tests with timeout-bounded `dd` against the actual media path and transcode cache path.
4. Check LAN topology and latency from each reachable host:
   - server → router/NAS/client pings
   - client → router/server/NAS pings
   - NAS → router/server/client pings
   - Any wired host showing ~100ms+ to the router is pathological; do not bury that under Jellyfin tuning.
5. Measure throughput per pair/direction:
   - Prefer `iperf3` when installed on both endpoints.
   - If one endpoint lacks iperf3 and installation is out of scope, copy/run a tiny Python TCP sender/receiver under `/tmp` and clean it later.
   - Test both directions because asymmetric failures are common.
6. Compare WAN per device only after LAN is characterized:
   - `speedtest-cli --simple` where available.
   - `curl -4 -L --max-time 45 -o /dev/null -s -w 'speed=%{speed_download} bytes/s total=%{time_total}s code=%{http_code}\n' <known test file>`

## Interpreting results

- Server/NAS good + one client terrible = client path/cable/switch/NIC issue, not a general Jellyfin/NAS issue.
- Wired PC reporting `1000Mb/s Full Duplex` but showing 300ms ping and 1–10 Mbit/s transfer indicates a bad cable/port, Realtek driver issue, or EEE pathology.
- Server on Wi‑Fi can still be adequate if pings are low and throughput is hundreds of Mbit/s, but wiring it remains a durability improvement.
- Jellyfin `TranscodeKiller` kill loops and missing HLS chunks are a software/config playback failure even if LAN is also bad.

## Low-risk remediation candidates

Ask before changing live network settings. For a Realtek PC path with EEE enabled:

```bash
sudo ethtool --set-eee enp42s0 eee off
```

Then immediately retest ping and bidirectional throughput. If it fixes latency, make the change persistent with the distro/network manager later. If not, swap cable/port before deeper Jellyfin work.

For Jellyfin-side stutter after network is ruled out:

- Disable/remove or relax Transcode Killer for 4K/HLS/remux sessions.
- Move Jellyfin transcode temp/cache to local SSD rather than NFS.
- Enable segment deletion.
- Enable the actual available hardware acceleration path and verify with logs during playback.
