---
name: distributed-agent-runtime-operations
description: Diagnose and recover persistent agent backends with desktop/mobile clients, reverse proxies, tunnels, pairing, and split-horizon routing.
version: 1.0.0
created_by: agent

metadata:
  harness: [hermes]
---

# Distributed Agent Runtime Operations

Use for a persistent local/server agent backend which is accessed by desktop or mobile clients through LAN proxies, public tunnels, pairing links, or remote-control transports.

## Operating model

Treat the system as separate layers, each requiring its own proof:

1. Client runtime and its saved connection/session state.
2. Client DNS, routing, IPv4/IPv6, clock, and TLS trust.
3. LAN reverse proxy and split-horizon DNS.
4. Public edge/tunnel transport.
5. Server process owner, listener, and backend state.

A successful HTTP request from the server does **not** prove the affected client can fetch, authenticate, or open a WebSocket.

## Read-only diagnosis

1. Identify the intended owner before changing anything: systemd user service, desktop launcher, Docker tunnel connector, etc. Never add a second backend process to "test" a persistent service.
2. Probe backend origin, public hostname, and forced LAN-proxy hostname independently. Record HTTP status, remote IP, and latency.
3. Locate the failing device from an active TCP connection, a fleet inventory, or user context. Run the same certificate-verified fetch from that device through SSH.
4. On the device, inspect:
   - DNS results and configured resolvers;
   - whether IPv6 records exist while the device lacks IPv6 routing;
   - time/NTP status;
   - desktop/mobile app process state and structured logs;
   - the exact backend/client versions.
5. Test WebSocket routes only with valid auth/tickets; an unauthenticated `401` only proves that the HTTP route is reachable, not that pairing works.

## Client/runtime recovery

- Desktop applications may run a separate local backend, often on the same nominal port as the server but on another host. Distinguish these explicitly.
- If the desktop runtime itself is stale, terminate its **known top-level PID** cleanly, wait for children/listeners to exit, and launch it using the live graphical session environment. Do not use broad `pkill -f` expressions which can kill SSH or unrelated Electron processes.
- Preserve the desktop app's known secure-storage option when relaunching; do not silently downgrade password storage.
- Do not blank/reset client state merely because pairing fails. Back up and inspect connection state first; reset only when the user explicitly asks for a blank slate.

## DNS and TLS pitfalls

- Multiple DHCP DNS servers can race. A client may bypass a local split-horizon record even when the server itself resolves locally.
- A Cloudflare Origin CA certificate is valid between Cloudflare and an origin, but ordinary clients do not trust it. Do not direct a normal LAN client to an Nginx endpoint using only that certificate unless the client trust store was intentionally configured. Either deploy a publicly trusted certificate for the LAN vhost or use the public edge path.
- Prefer the same HTTPS hostname for LAN and WAN. Do not tell browser/Electron clients to use raw `http://LAN-IP:port` unless the application explicitly supports it.

## Version alignment

For nightly/fast-moving agent software, compare the server runtime version with the desktop/mobile build. A package registry can advance before a desktop artifact is published.

When a mismatch plausibly coincides with connection failure:

1. Identify the newest mutually available build.
2. Preserve service state; change only the scoped runtime package.
3. Verify native dependencies required by the backend after install.
4. Restart the canonical process owner, wait for warm-up, and reprobe all paths.
5. Generate a new pairing credential only after both ends are stable.

## Scheduled-agent and gateway failures

When a scheduled agent reports a transport-style error (for example a broken pipe), first distinguish **agent execution**, **scheduled workload**, and **delivery**:

1. Inspect the scheduler log for the job ID and the request/retry sequence. A provider-stream failure can occur before the workload gets any tool call; it is not evidence that the monitored backup/service failed.
2. Inspect the job's latest status and delivery error separately. A successful execution with a Discord delivery failure is a routing problem, not a failed health check.
3. Trigger one scoped manual run of the existing job after checking its safety prompt and side-effect boundaries. Treat a successful rerun as recovery evidence, while preserving the original log evidence for the actual cause.
4. If the provider's event-stale watchdog prematurely terminates otherwise healthy Codex streams, raise its configured stale-event timeout conservatively, retain a backup of the prior environment file, and restart the canonical gateway owner before expecting the new value to take effect.
5. Never claim the workload was repaired solely because the provider retry succeeded; report both the completed rerun and any remaining restart/config activation step.

## Controlled recovery

When the user explicitly requests a clean backend reset:

1. Stop the canonical service and verify its listener disappears.
2. Restart the named tunnel/proxy connector, not the entire Docker host.
3. Start the canonical service normally.
4. Wait for local readiness; startup probes may transiently refuse or time out.
5. Verify local origin, public edge, and LAN proxy independently.
6. Do not claim the client is fixed until the client-side probe or user confirms it.

## Pairing credential handling

Pair URLs/tokens are time-limited access credentials. Keep them out of logs, diagnostics, screenshots, and shared channels by default. Deliver them in a shared channel only when the user explicitly asks. Label credentials by device/purpose and regenerate rather than reusing an uncertain old token.

## Reporting

Lead with the failing layer, not a generic "service is healthy." State which probes were run from the actual client, what was changed, and the remaining client action. Do not conflate server HTTP health with authenticated real-time connection health.
