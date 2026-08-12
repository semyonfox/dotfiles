---
name: remote-desktop-service-recovery
description: "Use when diagnose and recover a remote desktop app connection to a self-hosted backend without resetting state or confusing server and client runtimes."
version: 1.0.0
created_by: agent

metadata:
  harness: [hermes]
---

# Remote Desktop Service Recovery

Use when a desktop application on a reachable workstation cannot connect to a self-hosted service, especially after a host reboot, tunnel restart, or desktop-app update. Treat the server backend, reverse proxy/tunnel, client network path, and desktop-local runtime as separate owners.

## Workflow

1. **Verify the service owner first.** Stop/restart it through its intended supervisor (for example systemd or Compose), not by launching a second manual process. Confirm the port closes before start, then verify the ready endpoint locally.
2. **Verify every intended ingress independently.** Test the public hostname and the LAN reverse-proxy route. A root-page HTTP 200 is insufficient; probe the application environment/health endpoint used by the desktop client.
3. **Test from the exact active workstation.** Do not infer its route from server-side DNS. SSH to the active workstation and run a normal certificate-validating HTTPS request to the same endpoint. Inspect its resolver results, IPv4/IPv6 availability, and application processes.
4. **Separate the desktop-local backend from the remote backend.** Many desktop apps launch a local helper/backend on a loopback or workstation-local port. A stale local process/catalog can survive while the remote service is entirely healthy.
5. **Restart the desktop runtime before resetting state.** Gracefully terminate the known desktop leader PID, confirm its children are gone, launch it through the live graphical session, and verify its local helper starts. Preserve client state directories unless the user explicitly requests a blank slate.
6. **Only then issue new pairing/auth material.** A pairing credential cannot repair a broken local app runtime or TLS/DNS route. Treat it as short-lived access material; do not expose it unnecessarily.

## Split-horizon DNS and TLS

- Test split DNS from the client itself. A client configured with both a local resolver and public DNS may receive either answer depending on resolver behavior.
- A Cloudflare Origin CA certificate is appropriate for Cloudflare-to-origin traffic but is not generally trusted by ordinary LAN clients. If local DNS points directly at an Nginx origin using that certificate, a standard client may reject HTTPS. Prove normal trust validation; do not use `curl -k` as health evidence.
- If a public hostname and public certificate work from the workstation, do not blame Cloudflare without checking the desktop app's local runtime and logs.

## Background agent GUI bridge on a remote workstation

When an agent must inspect or operate a native application on a reachable workstation **without taking over the user's active workspace**, use a background computer-use driver rather than treating SSH + compositor process inspection as equivalent to remote desktop control.

1. Verify the configured SSH desktop alias and the active graphical session first.
2. Install Cua Driver on the workstation using its canonical installer:
   ```bash
   /bin/bash -c "$(curl -fsSL https://cua.ai/driver/install.sh)"
   ```
3. Start its user-owned daemon with the actual graphical-session environment (`XDG_RUNTIME_DIR`, `WAYLAND_DISPLAY`, `DISPLAY` where XWayland is in use, and `DBUS_SESSION_BUS_ADDRESS`). On Hyprland, a reliable launch shape is:
   ```bash
   systemd-run --user --unit=cua-driver --collect \
     --property=Environment=DISPLAY=:0 \
     --property=Environment=WAYLAND_DISPLAY=wayland-1 \
     --property=Environment=XDG_RUNTIME_DIR=/run/user/<uid> \
     --property=Environment=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/<uid>/bus \
     ~/.local/bin/cua-driver serve --socket ~/.cache/cua-driver/cua-driver.sock
   ```
   Substitute live values discovered from the session; do not assume them.
4. Expose it to Hermes over SSH as an MCP server, keeping the socket local to the desktop:
   ```bash
   hermes mcp add cua-driver-pc --command /usr/bin/ssh --connect-timeout 30 \
     --args -o BatchMode=yes <desktop-alias> ~/.local/bin/cua-driver mcp \
     --socket ~/.cache/cua-driver/cua-driver.sock
   ```
   MCP registration changes sensitive agent configuration: use `hermes mcp add`, not a direct config-file edit. The user must start a fresh Hermes session before the new tools are available.
5. **Prove the server-to-driver route before promising control.** Run `hermes mcp test cua-driver-pc` and record both a successful connection and discovered-tool count. This validates the SSH command, remote MCP endpoint, and local desktop socket as one path; it does **not** prove an already-running chat has those tools in its schema.
6. Start a **fresh Hermes session** after MCP registration (or after a toolset reload only where the platform supports it). MCP tools are normally fixed at session startup. Do not claim that the agent can operate the target until the fresh session actually exposes the driver tools.
7. Capture/inspect the target application by PID and follow the driver's background action ladder. Do not activate the target workspace merely to inspect it; escalate only after the driver reports that background delivery is ineffective. For native games, background key delivery may be rejected by the game input stack: capture and verify the in-game state after every action, and request explicit user permission before any foreground escalation.

This is suitable for pre-authorized work inside a desktop app or game, but never use it for credentials, payments, permission prompts, or 2FA.

## Handoff discipline

If tool schemas cannot be refreshed in the current messaging thread, write a concise handoff rather than implying configuration happened. Include: the target app/workspace constraint, MCP server name and verified `mcp test` result, exact in-app prerequisite commands, config/bind file location and whether it actually exists, desired changes, and a verification-first resume checklist. Keep game-specific build advice separate from the desktop-control procedure.

## Graphical Linux workstation recovery

For a Wayland/Hyprland workstation, establish the graphical environment before relaunching an app remotely:

```bash
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export HYPRLAND_INSTANCE_SIGNATURE=$(ls -1 "$XDG_RUNTIME_DIR/hypr" | head -n1)
```

Use a known PID for termination. Avoid broad `pkill -f` patterns: they can match the remote shell command itself. Launch through the compositor or a user systemd scope with the application's established Wayland and secure-storage flags, then confirm both the process tree and its local readiness endpoint.

## Verification checklist

- Intended server process is the only owner of its port.
- Public and LAN endpoints return the expected status.
- The exact workstation can reach the endpoint with certificate validation enabled.
- Desktop-local helper is running after relaunch.
- The user can complete the pairing/connection flow.

## Pitfalls

- Do not repeatedly restart the server when a workstation-local desktop helper is stale.
- Do not reset or delete desktop state merely because a connection fails; preserve it and recover the runtime first.
- Do not call a LAN route healthy based only on an insecure TLS probe.
