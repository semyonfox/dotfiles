# RustDesk remote code retrieval across Semyon's device fleet

Use when Semyon asks for a “RustDesk code,” “RustDesk ID/password,” or similar quick remote-access details for one of his own machines.

## Fast path

1. Identify the likely target from context. If unspecified, probe the normal fleet aliases in this order before asking: `pc` / `winpc` / `semyons-pc` / `10.0.0.15`, then `laptop` / documented Tailscale fallback, then the local host.
2. Use short SSH timeouts and read-only discovery first:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=6 pc \
  'hostname; command -v rustdesk || true; pgrep -a rustdesk || true; rustdesk --get-id 2>&1 || true'
```

3. If RustDesk is installed and running, get the ID with whichever binary exists:

```bash
rustdesk --get-id 2>/dev/null || /usr/share/rustdesk/rustdesk --get-id 2>/dev/null
```

4. Generate a fresh temporary unattended password rather than trying to decrypt or print an existing stored password:

```bash
PASS=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 10)
rustdesk --password "$PASS" >/tmp/rustdesk-setpass.log 2>&1 \
  || /usr/share/rustdesk/rustdesk --password "$PASS" >/tmp/rustdesk-setpass.log 2>&1 \
  || true
ID=$(rustdesk --get-id 2>/dev/null || /usr/share/rustdesk/rustdesk --get-id 2>/dev/null)
printf 'ID=%s\nPASS=%s\n' "$ID" "$PASS"
```

5. Verify the service/tray processes are still present with `pgrep -a rustdesk`, then reply with only the concrete ID/password unless extra context is needed.

## Pitfalls

- RustDesk config files may contain encrypted `password`, `enc_id`, salts, and key material. Do **not** paste those into chat; report only the usable ID and freshly generated password.
- The local server may have stale/broken RustDesk AppImage symlinks even when the target PC has a working system install. Do not stop at the local host if the request likely means Semyon's desktop.
- The `laptop` SSH alias may route through NAS/LAN and fail while the device is reachable another way. Use the documented Tailscale fallback from the device-fleet reference before giving up.
- RustDesk may be installed as `/usr/bin/rustdesk` while the running UI/server processes show `/usr/share/rustdesk/rustdesk`; try both paths.
