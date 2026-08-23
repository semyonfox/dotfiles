# Semyon's Device Fleet

Use this file to identify the right machine before acting. It is a **current operational inventory**, not a maintenance diary. Keep service procedures in their own skills/references and use Git history for past work.

Last verified: 2026-08-23 from read-only local/SSH probes.

## Fleet at a glance

| Device / nickname           | Purpose                                                                   | LAN IP      | Tailscale IP      | Access                                                                          | Current OS / user                                | Status / caveat                                                                                                                   |
| --------------------------- | ------------------------------------------------------------------------- | ----------- | ----------------- | ------------------------------------------------------------------------------- | ------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------- |
| `server`                    | Always-on control node: Hermes, headless agents, T3 Code, Docker/services | `10.0.0.5`  | `100.118.61.122`  | local shell or `ssh server`                                                     | Ubuntu 24.04 / `semyon`                          | Primary agent host                                                                                                                |
| `nas`                       | NAS storage, Btrfs/NFS, storage-side Docker                               | `10.0.0.6`  | `100.65.148.17`   | `ssh nas`                                                                       | Debian 12 / `semyon`                             | Storage and mount changes are high-risk                                                                                           |
| `pc` / `semyons-pc`         | Main desktop: GUI, GPU, DaVinci, games, Windows/Linux dual boot           | `10.0.0.15` | `100.77.148.51`*  | **Current:** `ssh pc` (CachyOS, `semyon`) or `ssh foxsc@10.0.0.15` when Windows | CachyOS / `semyon` (dual boot Windows / `foxsc`) | Which OS is booted decides which endpoint works; verify before OS-specific work (2026-08-23: CachyOS side reachable via `ssh pc`) |
| `laptop` / `semyons-laptop` | Mobile ThinkPad workstation                                               | `10.0.0.17` | `100.127.128.15`  | `ssh laptop` via NAS proxy; fallback `ssh semyon@100.127.128.15`                | CachyOS / `semyon`                               | LAN/NAS-proxy access worked on 2026-08-18                                                                                         |
| Samsung SM-A546B            | Android phone; low-priority/mobile use                                    | Unknown     | `100.84.250.104`* | No SSH path documented                                                          | Android                                          | Historically offline; do not assume reachable                                                                                     |
| Xiaomi 11T Pro              | Android phone; low-priority/mobile use                                    | Unknown     | `100.104.248.28`* | No SSH path documented                                                          | Android                                          | Historically offline; do not assume reachable                                                                                     |
| router                      | LAN gateway / DHCP / DNS / Wi-Fi                                          | `10.0.0.1`  | N/A               | No admin path documented                                                        | Unknown                                          | Do not change routing, DNS, DHCP, VPN, firewall, or Wi-Fi without explicit approval                                               |

\* Historical Tailscale address; verify reachability before relying on it.

## Specs and constraints

### `server`

- Dell XPS 15 9570, Ubuntu 24.04.
- NVIDIA GTX 1050 Ti Max-Q with 4 GiB VRAM: fine for light GPU work, not a large-model inference box.
- Default host for headless agents, Docker/service work, and fleet coordination.
- Do not confuse Docker bridge addresses with physical fleet addresses.

### `nas`

- Debian 12 NAS/storage and Docker host.
- Use for Btrfs, NFS, shares, backup destinations, and storage-side containers.
- Treat disks, pools, mounts, snapshots, shares, and Docker volumes as high-risk. Read-only inventory first; ask before mutation.

### `pc`

- MSI MS-7C91 desktop; Ryzen 5 5600G, Radeon RX 6600; Windows/CachyOS dual boot.
- The SSH endpoint depends on the booted OS: CachyOS answers as `semyon-pc-cachy` via `ssh pc` (verified 2026-08-23); Windows answers as `foxsc@10.0.0.15` (verified 2026-08-18).
- Use for GUI, GPU, DaVinci Resolve, interactive development, and gaming-adjacent work.
- Preserve active Brave/media playback unless Semyon explicitly authorizes disruption.

### `laptop`

- ThinkPad X1 Carbon Gen 9 running CachyOS.
- Use for mobile GUI/workstation work.
- The configured `laptop` alias reaches the LAN address through `nas`; use the raw Tailscale address only if that route fails and the node is online.

## Routing rules

- “Server” means `server` unless Semyon says otherwise.
- “PC” means the physical machine at `10.0.0.15`; check whether Windows or CachyOS is booted before doing OS-specific work.
- “Laptop” means `semyons-laptop`.
- “NAS” means `nas`; do not mutate storage/network state without explicit approval.
- Start with a short, read-only probe: `ssh -o BatchMode=yes -o ConnectTimeout=8 <host> 'hostname; id -un'`.
- Prefer the existing SSH alias, then LAN IP, then a recently verified raw Tailscale IP. Do not assume MagicDNS or historical Tailscale entries work.
- Keep T3 Code details in `references/t3-code.md`, not here.
- Never record passwords, private keys, tokens, recovery codes, or browser/session data in this inventory.
