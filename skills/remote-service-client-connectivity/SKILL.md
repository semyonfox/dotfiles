---
name: remote-service-client-connectivity
description: Diagnose client connection failures to remotely exposed self-hosted services without mistaking HTTP reachability for an authenticated realtime connection.
version: 1.0.0
created_by: agent

metadata:
  harness: [hermes]
---

# Remote Service Client Connectivity

Use for a self-hosted service exposed through a reverse proxy, tunnel, split-horizon DNS, or relay when a desktop/mobile client says it cannot connect even though a browser or `curl` returns HTTP 200.

## Core rule

Do not repeatedly restart the server or mint access credentials as the first response. Separate the layers and prove the client-relevant transport.

1. Identify the intended owner for the backend, proxy/tunnel, and **actual affected client device** before stopping anything. Do not infer the client from another paired desktop, a remote-control path, or a similarly named host. Record a role map: server, affected client, and incidental/locked devices.
2. Where the server records client sessions, inspect the newest session’s user agent, label, issuance time, and last-connected time. This can identify the real client build and prove auth-then-disconnect even when the client is inaccessible. A version from an unrelated desktop is not evidence about the affected client.
3. Verify local origin, LAN-proxy path, and public path independently. Record DNS answers from the actual client device, not only the server.
4. For realtime services, verify an **authenticated WebSocket/RPC** connection. A `GET /ws` response such as `401` proves route reachability only; it does not prove an upgrade will work.
5. If the authenticated public socket succeeds, preserve the server and focus on the affected client’s cached environment/session, local backend, version, resolver, or trust store.
6. Only restart the smallest owning component after evidence points to it. Verify the exact client path again afterward.

## Authenticated WebSocket probe pattern

When the service issues browser sessions and WebSocket tickets, create a labeled, short-lived internal pairing credential. In a temporary directory with restrictive permissions:

1. Exchange the pairing credential at the service browser-session endpoint and retain the returned cookie only in a temporary cookie jar.
2. Request a WebSocket ticket using that cookie.
3. Connect to the service's public `wss://…/ws?<ticket-param>=…` endpoint with a small client probe.
4. Delete the temporary cookie jar, payload, ticket, and credential artifacts after the result.

Never print the internal credential, session cookie, bearer token, or ticket. A successful socket upgrade proves the public proxy/tunnel and backend realtime path; it does not prove a particular app's cached client state.

## Split-horizon DNS and TLS

- Query the resolver used by the affected client. DHCP or NetworkManager configurations with multiple DNS servers can race; a server-side `dig` result is not proof of the client answer.
- Test both the public hostname and a forced LAN-IP route with normal certificate verification.
- A Cloudflare Origin CA certificate is appropriate for Cloudflare-to-origin traffic but is not normally trusted by LAN clients. Do not force clients onto a split-horizon origin using that certificate without a client-trusted certificate plan.
- Prefer one canonical HTTPS hostname. Do not hand users an insecure direct HTTP origin except for controlled diagnostics.

## Client-local runtimes

Desktop apps may launch an independent local backend even when they are configured to connect to a remote service. Inspect the actual client process and its logs from the affected device. Restart the known application leader cleanly and relaunch through its live graphical-session environment when needed; do not delete user state as a generic connection fix.

Version alignment should follow upstream compatibility channels, not arbitrary exact build strings. In particular, a mobile preview built from the current development branch can be newer than a packaged desktop client. Keep the shared server on its intended current channel unless an incompatibility is demonstrated by upstream evidence.

## Notifications

Treat realtime in-app updates and background OS push separately. A client can have notification support and permission but receive no push if the server has no authorised/provisioned relay or has activity publishing disabled. Inspect the server's notification/relay status before claiming push is enabled. Starting a provider or relay authorization flow is an external side effect and requires user approval.

## Reporting

Lead with the proven failing layer and the next smallest fix. State separately:

- local origin health;
- LAN DNS/proxy/TLS health;
- public DNS/proxy/TLS health;
- authenticated realtime transport health;
- affected client process/session status; and
- push-notification relay status.
