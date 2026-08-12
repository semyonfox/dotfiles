# Split-horizon Pi-hole LAN DNS audit

Use this reference when LAN users report that `*.semyon.ie` services, especially Cloudflare Tunnel services, go out to Cloudflare and back instead of staying local.

## Read-only audit pattern

1. Confirm the host's LAN view:
   - `ip -br addr`
   - `ip route`
   - inspect `/etc/resolv.conf`
   - if systemd-networkd is active: `networkctl status <iface>`
2. Compare DNS answers from all relevant resolvers:
   - default resolver: `dig +short immich.semyon.ie A`
   - public: `dig +short @1.1.1.1 immich.semyon.ie A`
   - router: `dig +short @10.0.0.1 immich.semyon.ie A`
   - Pi-hole/server: `dig +short @10.0.0.5 immich.semyon.ie A`
3. Check whether router DHCP advertises itself or Pi-hole:
   - `networkctl status <iface>` often shows DHCP-provided DNS/search domains.
   - If clients receive `10.0.0.1` and Pi-hole logs show queries from `10.0.0.1`, the router is acting as a DNS forwarder/proxy to Pi-hole. That works but hides individual clients behind the router.
4. Check Pi-hole state/config without changing it:
   - `docker ps` for `pihole` and port 53 bindings.
   - `docker exec pihole pihole status`
   - inspect `/etc/pihole/custom.list` and `/etc/pihole/pihole.toml` for `dns.hosts`, upstreams, DHCP active, and listening mode.
   - tail `/var/log/pihole/pihole.log` for the queried hostname and client IP.
5. Probe the local service before proposing DNS overrides:
   - For Immich: `curl -i http://10.0.0.5:2283/api/server/ping`
   - For local HTTPS vhosts, force the hostname to the LAN IP and check the exact name that would get a Pi-hole override:
     - `curl -kIsS --resolve photos.semyon.ie:443:10.0.0.5 https://photos.semyon.ie/`
     - `curl -kIsS --resolve immich.semyon.ie:443:10.0.0.5 https://immich.semyon.ie/`
   - Compare the working legacy/alias hostname against the intended hostname. If `photos.semyon.ie` returns Immich but `immich.semyon.ie` returns `502`, the DNS override is premature; Nginx lacks a matching local vhost/server_name for the new hostname.
6. For Pi-hole's own web UI, verify the actual published port before trusting old Nginx configs or dashboard links:
   - `docker ps` may show Pi-hole web as `8089:80`, while an older local Nginx vhost may still proxy to `10.0.0.5:8053`.
   - Probe both when uncertain: `curl -IsS http://10.0.0.5:8089/admin/` and `curl -IsS http://10.0.0.5:8053/admin/`.
   - Do not add `pihole.semyon.ie -> 10.0.0.5` until the local Nginx vhost reaches the actual port and returns a real Pi-hole response instead of `502`.

## Interpretation

If Pi-hole and router both return Cloudflare public IPs such as `104.21.x.x`/`172.67.x.x` for a LAN-hosted service, there is no split-horizon/local DNS override. LAN traffic will hairpin through Cloudflare/Tunnel.

A correct split-horizon fix is usually two-part:

1. Ensure a local reverse-proxy vhost exists for the exact hostname.
   - Do not add DNS first if Nginx will route the hostname to a default/wrong vhost.
   - For Immich, `photos.semyon.ie` may already proxy to `http://10.0.0.5:2283`; add `immich.semyon.ie` to that server block or create a matching vhost.
2. Add explicit Pi-hole local DNS records for the LAN hostnames, e.g.:
   - `immich.semyon.ie -> 10.0.0.5`
   - `photos.semyon.ie -> 10.0.0.5`
   - `jellyfin.semyon.ie -> 10.0.0.5`

Prefer explicit records over wildcard `*.semyon.ie` unless every subdomain has been checked; a wildcard can hijack public-only/tunnel-only services.

## Router/Pi-hole DHCP tradeoff

- Router advertises `10.0.0.1` as DNS and forwards to Pi-hole: simpler, but Pi-hole sees the router as the client.
- Router advertises `10.0.0.5` directly: Pi-hole sees individual clients, but this requires safe router DHCP changes and client lease refreshes.
- Pi-hole DHCP: possible but more disruptive; only do with explicit approval.

## Pi-hole v6 dnsmasq include pitfall

- On Pi-hole v6, a clean local-DNS method is a dnsmasq include under `/etc/dnsmasq.d/` with `pihole-FTL --config misc.etc_dnsmasq_d true`, e.g. `address=/t3.semyon.ie/10.0.0.5`.
- Do not store backup copies inside `/etc/pihole/hosts/`: FTL treats files in that directory as hosts sources, so `custom.list.backup-*` can keep stale overrides alive even after `custom.list`/`pihole.toml` are cleaned. Move such backups under `/etc/pihole/config_backups/` or outside the mounted hosts directory, then restart/reload Pi-hole.
- If an old override appears sticky, grep active sources: `grep -R "hostname" -n /etc/pihole/hosts /etc/dnsmasq.d /etc/pihole/pihole.toml`.

## Safety

DNS, DHCP, router, tunnel, and reverse-proxy changes can break access. Do read-only discovery freely, but get approval before applying changes, especially router DHCP/DNS changes or broad Pi-hole wildcards.