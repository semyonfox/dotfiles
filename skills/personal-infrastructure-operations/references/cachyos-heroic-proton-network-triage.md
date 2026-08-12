# CachyOS Heroic / Proton and PC LAN-latency triage

Use for Semyon's CachyOS gaming PC when Heroic, Proton, downloads, or game responsiveness are reported as broken.

## Safe order of operations

1. **Do not blame Proton first.** Measure PC → router, PC → server, and PC → NAS latency/loss during the reported download/game workload. Also measure server/NAS → router to isolate the bad hop.
2. Inventory the current stack before changing it:
   - `pacman -Qu`, `paru -Qua`
   - `pacman -Q heroic-games-launcher-bin proton-cachyos-slr protonplus wine-cachyos-opt gamescope gamemode mangohud steam mesa vulkan-radeon lib32-vulkan-radeon`
   - `vulkaninfo --summary`; `/dev/ntsync`; `systemctl --user is-active gamemoded.service`
3. CachyOS's current supported non-Steam path is `umu-launcher` + `proton-cachyos-slr`. Install the CachyOS package when missing: `sudo pacman -S --needed umu-launcher`. Proton-CachyOS is deliberately bleeding-edge and includes staging/hotfix work; keep it for the default experimental path.
4. Refresh ProtonPlus runners after the network is usable: `protonplus update all`. Verify with `protonplus list heroic-games-launcher-system` and `protonplus list steam-system`.
5. Verify a real Heroic game process rather than only versions. A healthy launch has `umu_run.py`, pressure-vessel, Proton-CachyOS, and optionally GameMode/MangoHud in its process ancestry. **Redact command-line Epic auth arguments/tokens before reporting.**

## Realtek / powerline-style LAN pitfall

A PC can negotiate `1000Mb/s Full` with zero NIC errors yet exhibit hundreds of milliseconds of router latency and packet loss under download load. Check:

```sh
ethtool -i enp42s0
ethtool --show-eee enp42s0
ping -q -c 10 -W 1 10.0.0.1
```

If EEE is **enabled and active**, disable it temporarily and repeat the ping during the same workload:

```sh
sudo ethtool --set-eee enp42s0 eee off
```

Only if this objectively improves latency/loss, persist it with a small enabled systemd oneshot service:

```ini
[Unit]
Description=Disable Ethernet Energy Efficient Ethernet for low-latency gaming
After=NetworkManager.service

[Service]
Type=oneshot
ExecStart=/usr/bin/ethtool --set-eee enp42s0 eee off

[Install]
WantedBy=multi-user.target
```

Then `sudo systemctl daemon-reload && sudo systemctl enable <unit>`. Re-check `ethtool --show-eee` and router ping.

EEE relief does **not** prove the cable/powerline path is healthy. If local router latency or loss remains high, direct Ethernet or a proper Wi-Fi/mesh backhaul is the durable fix. Do not restart, kill, or reconfigure unrelated server/NAS services while diagnosing a PC-local Layer-2 path.

## Concurrent download handling

A Heroic Legendary update can starve package or runner downloads on a damaged path. Prefer to let it finish. If the user explicitly authorises intervention and a compatibility update is blocked, temporarily `SIGSTOP` only the exact `legendary update <app>` parent and workers, then always `SIGCONT` every paused PID and verify the updater has completed or resumed. Never stop the entire Heroic process group if another game is running.
