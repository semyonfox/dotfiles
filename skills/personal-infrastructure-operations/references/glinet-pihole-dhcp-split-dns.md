# GL.iNet + Pi-hole split-horizon DNS for LAN media services

Use this when LAN clients hit `*.semyon.ie` media services through Cloudflare Tunnel instead of staying local.

## Verified environment pattern

- Router: GL.iNet GL-MT6000 at `10.0.0.1`.
- Pi-hole: Docker container on server `10.0.0.5`, publishing DNS on `53/tcp` and `53/udp`.
- Router DHCP can advertise Pi-hole directly under `Network -> LAN -> DHCP Server -> DNS Server 1`.
- Best DHCP DNS setting for direct Pi-hole visibility:
  - DNS Server 1: `10.0.0.5`
  - DNS Server 2: blank, or `10.0.0.5` if the UI requires a value.
- Avoid public DNS as DHCP secondary, or some clients will bypass Pi-hole and split DNS randomly.

## Safe order

1. Compare answers through router, Pi-hole, and public DNS:
   ```bash
   for name in immich.semyon.ie jellyfin.semyon.ie pihole.semyon.ie; do
     echo "### $name"
     for r in 10.0.0.1 10.0.0.5 1.1.1.1; do
       printf '@%-8s ' "$r"
       dig +time=2 +tries=1 +short "@$r" "$name" A | tr '\n' ' '
       echo
     done
   done
   ```
2. Verify the local reverse-proxy vhost before adding a Pi-hole override:
   ```bash
   curl -kIsS --max-time 8 --resolve immich.semyon.ie:443:10.0.0.5 https://immich.semyon.ie/ | sed -n '1,10p'
   ```
   Do not point the DNS name at `10.0.0.5` until this returns the intended app response. A working backend on `:2283` is not enough if Nginx routes that host to a default/broken vhost.
3. Add only verified split-DNS records. For Pi-hole v6, prefer a dnsmasq include over editing the auto-generated `hosts/custom.list`:
   ```bash
   docker exec pihole sh -lc 'cat > /etc/dnsmasq.d/05-lan-split-dns.conf <<EOF
   # LAN split-horizon records managed manually
   address=/jellyfin.semyon.ie/10.0.0.5
   address=/immich.semyon.ie/10.0.0.5
   EOF
   pihole-FTL --config misc.etc_dnsmasq_d true >/dev/null
   pihole reloaddns >/dev/null || true'
   ```
4. Re-verify through both Pi-hole and router. Router answers should follow Pi-hole once it forwards to Pi-hole:
   ```bash
   dig +short @10.0.0.5 jellyfin.semyon.ie A
   dig +short @10.0.0.1 jellyfin.semyon.ie A
   ```
5. Renew/reconnect client DHCP leases so they receive DHCP DNS `10.0.0.5` directly.

## Nginx checks before DNS overrides

- `photos.semyon.ie` may be an old/alias vhost for Immich. If making `immich.semyon.ie` the proper LAN name, update the Immich vhost to include both names and prefer the canonical name:
  ```nginx
  server_name immich.semyon.ie photos.semyon.ie;
  ```
- For Pi-hole web, verify the actual published port from `docker ps`; stale Nginx configs may point at `8053` while the stack publishes `8089`.
- Always run `nginx -t` and reload Nginx before adding the matching Pi-hole override.

## When sudo is unavailable to the agent

If system files under `/etc/nginx` or `/etc/resolv.conf` need root and tool policy blocks password piping, do not force the DNS override anyway. Prepare a root-owned script for Semyon to run manually, and make it verify the vhost before enabling the DNS record. The important safety rule is: never create a split-DNS record for a hostname whose local vhost still returns `502` or the wrong app.

## Off-LAN/cache behaviour

Split DNS only affects clients using the LAN resolver/Pi-hole. Off LAN, clients use mobile/work/hotel DNS and get the public Cloudflare answer. The only expected annoyance is a short client/browser DNS cache when switching networks; reconnecting Wi-Fi or restarting the app clears it faster.
