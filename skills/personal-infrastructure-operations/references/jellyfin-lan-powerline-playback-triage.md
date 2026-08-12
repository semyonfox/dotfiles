# Jellyfin LAN / powerline playback triage

Use when Jellyfin playback is slow/stuttered and the user suspects LAN, frontend/client path, NAS, router, or server congestion.

## Pattern from session

A Jellyfin server can have two independent problems at once:

1. **Jellyfin playback/config problem** — e.g. Transcode Killer repeatedly killing HLS/remux jobs, Jellyfin then logging missing `/cache/transcodes/*.ts` segments.
2. **Client network path problem** — e.g. a PC on powerline Ethernet showing huge LAN latency and single-digit throughput even though the NIC reports `1000Mb/s Full`.

Do not collapse these into one cause. Test server↔NAS and client↔router/NAS/server separately.

## Read-only first checks

On server:

```bash
hostname -I
ip -br addr
ip route
findmnt /mnt/media || true
df -h /mnt/media / 2>/dev/null || true
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -i jellyfin || true
docker logs --since 2h --tail 200 jellyfin 2>&1 | grep -E 'TranscodeKiller|cannot serve|TranscodeManager|Playback'
```

For LAN quality, use both latency and throughput:

```bash
ping -c 20 -i 0.2 <router-ip>
ping -c 20 -i 0.2 <nas-ip>
ping -c 20 -i 0.2 <client-ip>
```

If `iperf3` is present on both endpoints, prefer it:

```bash
# receiver
iperf3 -s -1 -p 5220
# sender
iperf3 -c <receiver-ip> -p 5220 -t 10 --get-server-output
# reverse direction
iperf3 -c <receiver-ip> -p 5220 -R -t 10 --get-server-output
```

If `iperf3` is missing on one endpoint and installing is not worth it, use a small Python TCP sender/receiver copied to `/tmp` on both hosts. The important thing is bidirectional testing.

## Powerline-specific pitfall

Powerline adapters can report a normal 1G Ethernet link on the PC while the real path is unusable. Symptoms seen:

- PC NIC: `Speed: 1000Mb/s`, `Duplex: Full`
- PC/router ping: ~300ms average
- PC/server or PC/NAS packet loss: 5–20%
- Throughput: 1–20 Mbit/s
- Server↔NAS remains healthy enough at hundreds of Mbit/s

This points at the powerline path, electrical circuit/noise, adapter placement, or switch/cable around the powerline — not necessarily the server/NAS/router.

## EEE check / mitigation

Energy Efficient Ethernet can worsen Realtek/powerline weirdness. Check:

```bash
ethtool --show-eee <iface>
```

Temporarily disable:

```bash
sudo ethtool --set-eee <iface> eee off
```

Persist with a small systemd unit when the mitigation helps or the user asks for persistence:

```ini
[Unit]
Description=Disable Energy Efficient Ethernet on <iface>
After=network-pre.target
Wants=network-pre.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/ethtool --set-eee <iface> eee off
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

Then:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now disable-eee.service
systemctl is-enabled disable-eee.service
systemctl is-active disable-eee.service
ethtool --show-eee <iface>
```

Note: `ethtool` may live in `/usr/sbin` and not be on non-interactive SSH PATH.

## Interpretation guide

- **Router/NAS/server pings <5ms, client pings hundreds ms/loss:** client path/powerline problem.
- **Server↔NAS hundreds Mbit/s but client↔anything single-digit Mbit/s:** not a NAS/server bottleneck.
- **Jellyfin logs show `TranscodeKiller` and missing HLS segments:** fix Jellyfin config too; network repair alone will not fix all stutter.
- **EEE off barely improves path:** powerline/wiring remains the bottleneck; recommend real Ethernet first, strong Wi-Fi second, powerline placement/circuit cleanup third.
