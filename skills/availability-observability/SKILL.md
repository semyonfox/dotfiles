---
name: availability-observability
description: "Audit and present host, network-uplink, and service availability from existing system evidence before adding monitoring."
version: 1.0.0
created_by: agent

metadata:
  harness: [hermes]
---

# Availability Observability

Use this for uptime graphs, historical availability audits, outage attribution, or comparisons with cloud SLA/SLO figures.

## Core rule: do not conflate layers

Report and chart separate layers:

1. **Host uptime** — the OS was booted; derive from `wtmp`/`utmpdump` and pair each boot with the next shutdown or boot event.
2. **Network-uplink availability** — the host had a physical route to its LAN/Internet. This is not synonymous with Wi-Fi association.
3. **Service availability** — an endpoint was actually reachable and functioning. It cannot be inferred merely from an interface carrier state.

Never call host uptime “service uptime.” Never call an active Wi-Fi interface “network availability” without checking whether it was the sole uplink.

## Historical-first workflow

Before deploying a new probe or timer, exhaust existing evidence:

1. Inventory `wtmp`, journald, `syslog`, `kern.log`, and rotated/compressed variants. State the exact retained date windows.
2. Parse systemd-networkd/NetworkManager/iwd/wpa_supplicant logs for physical-interface events such as `Lost carrier`, `Gained carrier`, connect/reconnect, DHCP lease acquisition, link up/down, and driver resets.
3. Build disconnect/reconnect pairs; preserve timestamps and durations. Do not count Docker veth/bridge churn as host network loss.
4. At every candidate outage, inspect every actual physical interface and route: built-in Ethernet, Wi-Fi, USB Ethernet, Thunderbolt docks/adapters, and historical default routes. Check kernel/driver logs for USB/Thunderbolt Ethernet attachment. Tailscale/WireGuard/VPN tunnels are overlays, not independent internet uplinks.
5. Only classify the interval as a **confirmed host network-uplink loss** when the failed interface was the only available physical/default route during that interval. Otherwise describe it narrowly as an interface loss.
6. Explicitly label unobserved periods as `not retained`; do not extrapolate an all-time network percentage from shorter log retention.

## Calculations and claims

- Calculate every duration with a tool, never mentally.
- `host uptime − confirmed uplink loss` is a **best-case** connectivity figure, not a true end-to-end SLA: it misses router, DNS, ISP, or remote-service failures that leave a local link associated.
- Cloud SLAs are usually monthly and configuration-specific. Compare against the matching tier only: a single VM is not a multi-AZ/multi-zone deployment.
- Say “beats AWS’s single-EC2 SLA” only when comparing to the documented **single instance** commitment; never claim to be “better than AWS” overall.
- GitHub/status-page incident counts are component incident records, not a whole-company uptime percentage unless the status source explicitly publishes one.

## Presentation standard

For a Discord-readable timeline:

- Use stacked bars: **host booted** over the full `wtmp` window, then **network uplink** only in the period supported by network logs.
- Green = available/connected; red = confirmed uplink loss; grey = evidence not retained. Include a concise legend.
- Put the retention dates, raw source type, and caveat in the artifact itself.
- Show host uptime, confirmed uplink-loss total/count, and the best-case combined figure in clearly labelled cards.
- Render SVG to PNG and visually inspect it before delivery. Fix label/legend overlap and clipping rather than handing off an unreviewed graphic.

## Future monitoring — only when requested

Do not add a persistent monitor merely because historical evidence is incomplete. If the user explicitly wants ongoing measurement, use a lingering `systemd --user` oneshot timer (`Persistent=true`) with event logging for initial state, transitions, and hourly heartbeats. Probe LAN gateway, a direct-IP HTTPS endpoint, DNS, and a DNS-dependent web endpoint separately. Verify the unit and first record; remove it completely if the user decides that historical analysis is sufficient.

## Pitfalls

- Treating `wtmp` as proof that the network or a service was available.
- Misreading container `disconnected` logs or Docker veth carrier changes as a physical outage.
- Assuming Wi-Fi was the only route without auditing Ethernet/USB/Thunderbolt and route history.
- Turning an evidence-recovery request into unsolicited permanent monitoring.
- Comparing a long-window home-host percentage directly to a provider’s monthly, topology-specific SLA.
