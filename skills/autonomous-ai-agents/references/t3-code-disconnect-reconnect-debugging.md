# T3 Code Disconnect/Reconnect Debugging

Use this when T3 Code UI repeatedly disconnects/reconnects from its server, especially after a nightly/version bump, when users report intermittent prompt submission and red toast failures.

## High-signal pattern

A reconnect loop is not automatically a network/tunnel problem. In one live incident, basic HTTP reachability worked, but the app still failed because of a layered control-plane problem:

1. **Version drift:** the managed launch script expected a newer `t3@<nightly>`, but `command -v t3` found an older globally installed CLI first. The managed server silently ran the older binary instead of the script-pinned package.
2. **Native module install suppression:** npm skipped install scripts for `node-pty` / `msgpackr-extract`, causing `NodePtyModuleLoadError` after upgrade until reinstalled with allowed scripts.
3. **Duplicate server writers:** two T3 server processes were active against effectively the same state/base directory, producing SQLite contention such as `database is locked` during pairing/provider ingestion.

## Symptoms seen

```text
UI repeatedly disconnects/reconnects from the server
Prompt can sometimes be sent during a brief connected window
Prompt submission shows a red toast
SSH sessions appear/disconnect repeatedly
Pairing link creation fails
```

Useful log strings:

```text
provider runtime ingestion failed to process event
PersistenceSqlError: SQL error in OrchestrationEventStore.append:insert
Error: database is locked
ServerAuthPairingLinkCreationError: Failed to create pairing link
PairingCredentialIssueError: Failed to issue pairing credential
PersistenceSqlError: SQL error in AuthPairingLinkRepository.create:query
NodePtyModuleLoadError: Failed to load node-pty for linux-x64
Cannot find module './prebuilds/linux-x64//pty.node'
Rejected authenticated session credential
Invalid session token signature
```

## Triage sequence

1. **Check actual serving versions and paths, not just intended versions.**

```bash
t3 --version
command -v t3
node -e 'console.log(require("/usr/local/lib/node_modules/t3/package.json").version)' 2>/dev/null || true
```

Compare the version requested by any generated/managed launch script with the binary that `command -v t3` will actually execute. If the script pins `npx t3@X` but prefers an existing `t3` on PATH, an old global install can override the intended package.

2. **Check all local/listening T3 servers.**

```bash
ps -eo pid,ppid,stat,etime,comm,args | grep -Ei 't3|t3code|ssh .*3773|ssh .*3774' | grep -v grep
ss -ltnp | grep -E '3773|3774|38201'
```

If multiple servers are live, identify their base dirs and whether they share the same SQLite state.

3. **Verify endpoint identity, not just HTTP 200.**

```bash
curl -i http://127.0.0.1:3773/.well-known/t3/environment
curl -i http://127.0.0.1:3774/.well-known/t3/environment
curl -i http://127.0.0.1:<forwarded-port>/api/auth/session
```

A healthy HTML response only proves the listener/tunnel is reachable. It does not prove auth/session validity, matching server version, or prompt-submit path health.

4. **Look for SQLite lock and pairing errors around the failed prompt/pairing attempt.**

```bash
grep -RniE 'database is locked|PairingCredentialIssueError|ServerAuthPairingLinkCreationError|AuthPairingLinkRepository|OrchestrationEventStore|Invalid session token|Rejected authenticated session' ~/.t3-code/userdata/logs ~/.t3/userdata/logs 2>/dev/null | tail -100
```

5. **If native modules fail after npm install, reinstall allowing required scripts.**

```bash
npm install -g --allow-scripts=node-pty,msgpackr-extract t3@<expected-version>
```

Then verify module loading if practical before declaring the server fixed.

6. **Ensure only one server owns the SQLite state.**

If a persistent headless service and a managed remote/session server are both writing the same state, stop the duplicate writer. In the observed incident, disabling the persistent headless unit and update watcher stopped fresh DB-lock errors:

```bash
systemctl --user disable --now t3-code-headless.service t3-code-headless-update.path
systemctl --user reset-failed t3-code-headless.service
```

Then verify only one process owns `state.sqlite`, `state.sqlite-wal`, and `state.sqlite-shm`.

## Dev-facing takeaways

- Managed launch scripts should not blindly prefer any existing `t3` on PATH when the script pins a newer package version.
- Diagnostics should show active backend URL, environment id/label, server/client versions, resolved `t3` path, base dir/state DB path, listener PID, SSH tunnel mapping, and reconnect close reason.
- T3 should detect or warn when multiple server processes use the same SQLite state.
- `database is locked` during pairing/provider ingestion should surface as storage/contention, not generic server disconnect.
- Provider API failures can cause red toasts after submit, but they do not by themselves explain UI/server reconnect loops.
