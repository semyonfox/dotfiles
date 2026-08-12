# Current core device inventory

Private local inventory. Verified 2026-08-12 from live host/Tailscale probes unless stated otherwise.

| Device | Role | LAN IPv4 | Tailscale IPv4 | Access / state |
|---|---|---:|---:|---|
| `server` | Always-on services/control host | `10.0.0.5` | `100.118.61.122` | SSH alias `server`; online; advertises route `10.0.0.0/24`. |
| `nas` | NAS/storage | `10.0.0.6` | `100.65.148.17` | SSH alias `nas`; reachable on LAN; Tailscale peer last reported offline by server. |
| `pc` (`semyon-pc-cachy`) | CachyOS desktop/GPU | `10.0.0.15` wired; `10.0.0.165` Wi-Fi | **Not installed on current CachyOS PC** | SSH alias `pc`; prefer wired address. Old Windows PC Tailscale entry is not this machine. |
| Router (Flint 2) | LAN gateway | `10.0.0.1` | — | No changes without approval. |
| Polina laptop | CachyOS GNOME laptop | `10.0.0.139` observed/reachable; old note `10.0.0.138` is stale | Unverified | SSH refused; do not assume remote access. |
| Semyon's laptop | Mobile Linux device | Unverified; old SSH target `10.0.0.17` currently unreachable | `100.127.128.15` | Tailscale last seen 2026-08-09; SSH target currently unavailable. |
| Xiaomi 11T Pro | Android phone | Unverified | `100.104.248.28` | Tailscale last seen 2026-08-12; mobile device, no assumed SSH. |

## Retired/stale entries

- `SEMYONS-PC` / `100.77.148.51` is an offline **Windows** Tailscale node, not the current CachyOS PC.
- Samsung SM-A546B / `100.84.250.104` is expired; do not target it.

## Refresh

Use LAN probes for local addresses and `tailscale status --json` from a Tailscale host for overlay addresses. Update this table only from live evidence.
