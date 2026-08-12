---
name: device-fleet
description: "Use when working with Semyon's server, NAS, PC, laptop, phones, router, LAN, Tailscale, SSH, or home-network inventory."
---

# Device fleet

Use the private local inventory in `references/computers.md` before choosing a host. It is the source of truth for current LAN and Tailscale addresses; refresh it with read-only probes when reachability may have changed.

## Core roles

- `server`: always-on control/services host.
- `nas`: storage host; treat storage and shares as high-risk.
- `pc`: CachyOS desktop/GPU host; use for GUI work.
- Router: LAN gateway only; do not change it without explicit approval.

## Workflow

1. Prefer the SSH aliases in `~/.ssh/config`; use LAN on-site, then Tailscale/MagicDNS remotely.
2. Probe first: `ssh -o BatchMode=yes -o ConnectTimeout=8 <alias> 'hostname; ip -4 -o addr show scope global'`.
3. For Tailscale facts, use `tailscale status --json`; record only device name, address, state, and last verified date—never keys or tokens.
4. Mark unreachable devices as unverified, not failed. Do not guess an address from old documentation.
5. Before changing a remote host, inspect its active work/services and preserve unrelated work.

## Safety

Never reboot, alter router/firewall/Tailscale ACLs, repartition, modify NAS storage, or expose a service publicly without explicit approval.
