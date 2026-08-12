# Stateful remote desktop/app debugging

Use this when debugging tools that have a desktop/client, a remote/headless server, local tunnels, persisted credentials, and a local state database. The lesson from the T3 Code investigation is to avoid collapsing everything into “version mismatch” or “network flake”: split the layers and prove which one is closing the connection.

## Layer split

1. **Package identity**
   - Separate product branding from executable/package names.
   - Check desktop distribution, CLI/server package, global package manager install, and generated launch scripts independently.
   - Do not assume the desktop updater controls the remote server binary.

2. **Process and port ownership**
   - Record every live server process, parent process, command line, base/state directory, and listening port.
   - Check runtime files that claim a PID/host/port and verify the PID/command actually matches the expected app.
   - Look for duplicate managed and persistent/headless servers using the same state directory.

3. **State directory aliases**
   - Compare default and renamed state directories by inode/device, not just path text.
   - If the app changed names, verify whether old and new directories are symlinks/hard aliases or truly separate DBs.

4. **Connection lifecycle**
   - Correlate server-side connect/disconnect events with client tunnel/process logs and OS auth logs.
   - A server log that shows successful auth/connect followed by short-lived disconnect usually means “the transport was closed”, not “auth failed”.
   - Note repeated lifetimes that match client timeout/backoff constants.

5. **Tunnel isolation test**
   - Reproduce with the app-managed tunnel, then with a manually managed tunnel outside the app.
   - If the manual tunnel is stable but the app tunnel churns, focus on desktop environment reconciliation, bootstrap/target flapping, credential persistence, or tunnel scope cleanup.

6. **Clean-state isolation test**
   - Run a second server with a temporary base/state dir rather than deleting existing user state.
   - If clean state works, suspect persisted credentials, state DB bloat/corruption, or duplicate-writer history.
   - If clean state fails the same way, suspect transport/client lifecycle or network path.

## SQLite/state cautions

- WAL plus an in-process semaphore does not prevent cross-process write contention.
- Pairing/auth helper CLIs may write the same DB as the running server; check whether the source uses an interprocess lock or `busy_timeout`.
- Repeated reconnects can create many auth sessions/pairing links; growth may be symptom, cause, or amplifier. Use timestamps to distinguish.
- Before deleting state rows, inspect schema and references, not just table names: `PRAGMA table_info`, `PRAGMA foreign_key_list(<table>)`, indexes, min/max timestamps, live/expired/consumed breakdowns, and any other tables referencing the target tables.

## Auth/session table purge pattern

When a state DB has accumulated thousands of short-lived auth sessions or pairing links from reconnect churn, it may be safe to purge those tables **only after verifying they are self-contained auth/cache state**.

1. Stop the app server first so WAL state is stable and no writer races the purge.
2. Back up the DB and any `-wal`/`-shm` companions before touching it.
3. Verify target tables have no incoming/outgoing foreign-key dependencies and are not used for durable project/thread/provider history.
4. Prefer a graduated cleanup when possible:
   - expired/consumed/revoked pairing links first
   - stale sessions except the most recently connected handful
   - full auth reset only when the user accepts re-pair/re-auth
5. Use a single transaction, then checkpoint/VACUUM and run `PRAGMA integrity_check`.
6. Restart the server and verify process, port, runtime file, counts, and a simple health request.

Example Python purge skeleton, safer than hand-typing destructive SQL repeatedly and usable even when the sqlite CLI is absent:

```python
import os, signal, time, shutil, sqlite3, pathlib, datetime
home = pathlib.Path.home()
db = home / ".app/userdata/state.sqlite"
backup_dir = db.parent / "backups" / ("auth-purge-" + datetime.datetime.now().strftime("%Y%m%d-%H%M%S"))

# Find the exact long-running server process by /proc cmdline instead of `pkill -f`,
# which can match the current shell/script when the pattern appears in the command text.
pids = []
for p in pathlib.Path("/proc").iterdir():
    if not p.name.isdigit():
        continue
    try:
        cmd = (p / "cmdline").read_bytes().replace(b"\0", b" ").decode("utf-8", "ignore")
    except Exception:
        continue
    if " app-server-binary " in f" {cmd} ":
        pids.append(int(p.name))
for pid in pids:
    os.kill(pid, signal.SIGTERM)
for _ in range(30):
    if not any(pathlib.Path(f"/proc/{pid}").exists() for pid in pids):
        break
    time.sleep(0.2)

backup_dir.mkdir(parents=True, exist_ok=True)
for f in [db, pathlib.Path(str(db) + "-wal"), pathlib.Path(str(db) + "-shm")]:
    if f.exists():
        shutil.copy2(f, backup_dir / f.name)

con = sqlite3.connect(str(db), timeout=10)
cur = con.cursor()
cur.execute("PRAGMA foreign_keys=ON")
cur.execute("BEGIN IMMEDIATE")
cur.execute("DELETE FROM auth_pairing_links")
cur.execute("DELETE FROM auth_sessions")
con.commit()
cur.execute("PRAGMA wal_checkpoint(TRUNCATE)")
cur.execute("VACUUM")
assert cur.execute("PRAGMA integrity_check").fetchone()[0] == "ok"
con.close()
```

Pitfalls:

- Do not use broad `pkill -f 'pattern'` from inside a shell command that itself contains that pattern; it can terminate the tool’s own shell. Use exact `/proc/<pid>/cmdline` filtering or a pattern that cannot match the current command.
- Do not restart a server with shell-level `nohup ... &` under Hermes foreground terminal. Start long-lived servers with `terminal(background=true)` so Hermes tracks the process, then run readiness checks separately.
- Expect the app to create a fresh startup pairing link immediately after restart; that does not mean the purge failed.

## Report shape

For upstream reports, include:

- exact topology: desktop client, remote server, tunnel/proxy, provider
- current package/executable identities and paths
- earliest known occurrence from session/history if available
- process/port/base-dir snapshot
- connect/disconnect timeline with durations
- correlated OS/tunnel logs at the same timestamps
- ranked hypotheses with confirmation/denial tests

Avoid presenting a single confident root cause until at least one isolation test splits tunnel vs server vs state.

## Human-facing report workflow

When the user needs to post findings to Discord/GitHub/support, do not keep generating long polished “AI report” blocks in chat. Use a two-layer deliverable:

1. **Short human overview for chat** — plain language, first-person if the user is posting it, no excessive caveats, no forensic theatre. Say what happened, what was tried, what was ruled out, and the current best suspect in under the platform limit.
2. **Attachable full report** — markdown file with the gore: timeline, command outputs, logs, failed theories, code/source findings, and next tests.

If the user says the draft is too long, “de-AI it”, or that the thread is becoming a mess, stop iterating huge blocks. Condense aggressively, separate overview from evidence, and name the exact file to attach. For first-person reports, avoid “the assistant found” or “investigation concluded”; write like the user did the debugging: “I found…”, “I tried…”, “This did not fix it…”.

When a user challenges a vague hypothesis (“why not see what is making that process?”), pivot back to evidence immediately: inspect parents, systemd units/timers/path watchers/autostart files, process trees, and journals before writing more report prose.

## Headless backend as a user service

For remote/headless desktop-tool backends, do not leave the user with “no server running” after disabling a duplicate. Rebuild the intended automation so exactly one backend starts automatically:

1. Consult upstream docs and local `--help` for the supported headless command and flags.
2. Check whether `~/.old-name` and `~/.new-name` are the same inode before choosing a base/state dir.
3. Prefer one explicit user systemd service with `WantedBy=default.target`, `loginctl enable-linger <user>` if boot-without-login is required, and `Restart=on-failure` rather than a stale `Restart=always` service plus path watcher.
4. Keep update/path watchers disabled unless they are proven safe; they can resurrect old headless servers after package updates.
5. Add a preflight guard that refuses to start if another matching server process, target port, or DB holder exists. A failed start is better than a second SQLite writer.
6. Verify after enabling: `systemctl --user is-enabled/is-active`, process list, listener ports, health endpoint, DB file holders, and recent logs for `database is locked`.

Reusable starter unit: `templates/single-instance-headless-systemd.service`.

## Pairing and endpoint mistakes

When a browser pairing works but the desktop/client app reports that it cannot fetch `/.well-known/<app>/environment`, compare the exact URL the app is trying with the URL that actually works. Clients may drop a non-default port from the saved environment, turning a good endpoint such as `http://10.0.0.5:3773/.well-known/...` into `http://10.0.0.5/.well-known/...`, which may hit nginx/port 80 and redirect elsewhere.

Checklist:

1. Probe both the intended endpoint and the endpoint named in the error, including port and scheme.
2. If the app omitted the port, generate a fresh pairing link with an explicit `--base-url http://host:port` if the CLI supports it.
3. In manual fields, enter `host:port`, not just `host`.
4. Do not add nginx compatibility proxies until you have proven the client cannot store the port; first fix the saved endpoint.
5. After successful pairing, list active sessions/pairing links to confirm the client created a normal session and did not start another churn loop.
