# DaVinci Resolve network project server on the homelab

Use for a Resolve 18–21 multi-device Project Library backed by PostgreSQL, archive recovery, or a Docker port conflict on the server.

## Compatibility and topology

- Resolve 18–21 uses PostgreSQL **13**. Do not deploy an old PostgreSQL 12 target for a Resolve 21 workstation.
- Treat Resolve clients as requiring the PostgreSQL default port **5432**. Do not plan on solving a conflict with a `5433:5432` Docker mapping: Resolve's Network Project Library UI does not offer a supported custom-port field.
- PostgreSQL carries project metadata, not footage. Keep cache/proxies local to the editing machines and originals/exports on NAS storage.
- Never expose PostgreSQL as an unauthenticated/raw public service or open/forward port 5432 to the Internet. For remote Resolve teams, Cloudflare supports two secure patterns: (1) an Access-protected arbitrary-TCP Tunnel, where each client runs `cloudflared access tcp` and Resolve connects to its local `127.0.0.1:5432` listener; or (2) preferably for recurring collaborators, WARP private-network routing, where enrolled clients connect to the server LAN address normally. In both cases, enforce Cloudflare identity policy *and* individual PostgreSQL/Resolve credentials. Do not advertise a broad LAN subnet when only Resolve is required: publish/route only the Resolve host (`10.0.0.5/32`) and allow TCP 5432. A web administration dashboard may use a Cloudflare Tunnel only after Cloudflare Access is in place.

## Port-conflict procedure

When another database already owns the server's `IP:5432`:

1. Identify the exact owner with `ss -ltnp`, `docker ps --format '{{.Names}} {{.Ports}}'`, and `docker inspect` (compose project, mounts, networks, and restart policy).
2. Find host-facing callers separately from Docker-internal callers. Internal containers should use the service DNS name and port 5432, for example `pg-db:5432`; this does not need to change when only the host publication changes.
3. Take a logical backup of the displaced database before recreating it, hash it, and retain the path in the handover.
4. Rebind only its host publication to an unused explicit tuple, for example `10.0.0.5:55434:5432`. Bind it to the specific LAN IP, not `0.0.0.0`, unless public/other-interface access is deliberately required.
5. Validate `docker compose config`, recreate only that DB service (`up -d --no-deps db`), then verify:
   - database `pg_isready` and a simple query;
   - established API/application health probes using it;
   - old `IP:5432` is closed and new `IP:55434` is open.
6. Only after the old external tuple is free, deploy Resolve as `10.0.0.5:5432:5432`.

Do not move an existing database's external port without explicit user approval, because external developer tools or LAN clients may use it.

## Resolve stack shape

Keep tracked deployment files in `/home/semyon/server-stacks/resolve/` and private runtime/secrets in `server-stacks/data/resolve/` and a `0600 stack.env`.

Recommended services:

- `postgres:13`, with its data directory on the server's local SSD.
- a separate non-superuser Resolve role with `LOGIN CREATEDB`, generated password, and SCRAM host auth.
- `prodrigestivill/postgres-backup-local:13` writing rotated logical backups to a POSIX-capable NAS/NFS path.
- pgAdmin bound to `127.0.0.1` only; do not publish its Docker port directly.

Verification:

1. Validate Compose before pull/start.
2. Verify the database healthcheck, exact host binding, and a password-authenticated TCP connection as the Resolve role.
3. Manually run `/backup.sh` once and verify the backup artifact on NAS before trusting the schedule. That image's healthcheck has a long interval and can remain `starting` initially.
4. Configure its `POSTGRES_DB` list for every created Resolve library database. It backs up listed names, not an arbitrary future database automatically. **Before trusting or pruning backups, compare the live `pg_database` names with this list and inspect each dump's header** (`pg_restore -l` for custom archives; SQL header for plain dumps). A healthy backup container can otherwise keep producing valid archives for a retired database while omitting the live Resolve library.
5. For a manual pre-cleanup archive, record the exact live database name, creation time, archive format, and project count. Verify the custom archive with `pg_restore -l`; if a restoration test is needed, restore only to a separately named disposable/recovery database—never over the live library.
4. Configure its `POSTGRES_DB` list for every created Resolve library database. It backs up listed names, not an arbitrary future database automatically. Before trusting any backup, list the live non-template databases with `pg_database`, compare those exact names to the configured list, and inspect logical archive metadata (`pg_restore -l` for a custom dump, or the dump header) to confirm its `dbname` matches the live library. A syntactically valid archive of a legacy/renamed database is not recovery protection for the active Resolve library.
5. Validate both archive integrity and coverage: run `gzip -t` for scheduled `.sql.gz` artifacts; run `pg_restore -l` for custom dumps; then check the archive is for the expected database and was created after the protected change. Take a verified manual custom dump before destructive library cleanup.
6. Do not put live PostgreSQL data on NFS. NAS is appropriate for backup artifacts and snapshots.

## Archive discovery and migration safety

1. Inventory candidate sources first: `.drp`, `.dra`, `.drt`, project-backup directories, and Disk Database `Project.db`/`User.db` trees.
2. If an NTFS Windows drive is dirty but the user explicitly authorizes recovery, mount read-only first where possible; preserve the durable `chkdsk` recommendation. Copy sources rather than modifying them.
3. Stage copies from PC/Windows/NAS in a dedicated NAS migration directory with `rsync -a`; hash Disk Database files to identify actual duplicate project versions rather than relying only on names/timestamps.
4. A Disk Database directory is not a PostgreSQL library. Never copy raw `Project.db` files into PostgreSQL. Use Resolve's Network Project Library UI to create/add the database, then Resolve-supported project export/import or restore workflows.
5. Resolve must be running for the scripting API. The API can enumerate/export/import projects after a database is already registered, but adding the PostgreSQL connection requires the Project Manager Network UI. Capture the actual UI state when remote desktop automation is involved.

## Consolidating and pruning recovered sources

When Semyon asks for one manual-migration source set and explicitly authorizes removal of redundant originals:

1. Do not call a timed-out broad NAS walk “exhaustive.” Report the confirmed roots scanned (device dumps, editing/Resolve folders, mounted Windows volume, known staging tree, server user/service roots) and retain uncertainty about unscanned NAS areas.
2. Copy every discovered source into a single PC archive while keeping its origin namespace, for example `nas-device-dumps/`, `pc-linux-current/`, `pc-windows-ntfs/`, and `pc-legacy-windows/`. Include a README stating that source Disk Databases must not be raw-merged.
3. Hash every regular file before dedupe. Identical filenames are not enough. Exact duplicates can be replaced with hardlinks **within the same filesystem**; retain a JSON manifest mapping each hash to the canonical path and linked paths. `rsync -aH` preserves this layout when making a recovery replica.
4. Build one NAS recovery archive from the completed PC archive, then prove it matches with a checksum-mode dry-run such as `rsync -aHnrc --delete source/ target/`. Keep a manifest hash at both ends.
5. Only after both the PC archive and NAS recovery archive verify, and only after explicit deletion approval, prune the exact duplicate source directories. Record deleted paths/sizes in receipts inside the retained archives. Do not delete the PostgreSQL library, scheduled database backups, or any source outside the approved list.
6. For migration intake, hash `Project.db` files separately and select one canonical path per content hash. This reduces repeated imports but does **not** establish project identity or freshness; preserve the full archive until Resolve imports are validated project by project.

## Publishing deployment changes from a dirty server-stacks checkout

The live `/home/semyon/server-stacks` checkout can contain unrelated staged deletions, local env-file cleanup, generated artifacts, or another workstream's WIP. Do not `git add .`, reset its index, or commit its full staged state just to publish a Resolve/port-rebind change.

1. Fetch `origin/main` first. If the local checkout is behind, do not push its old `HEAD` directly.
2. Create a temporary clean worktree from `origin/main`.
3. Copy only tracked deployment files into it: the Resolve `stack.yaml`, init script, README, and the minimal incumbent-stack port-rebind hunk. Never copy `stack.env`, runtime data, NAS backup output, or generated credentials.
4. Validate Compose in the clean worktree (use `--no-interpolate` when its ignored `stack.env` is intentionally absent), run `bash -n` for init scripts, inspect the exact staged diff, and scan additions for literal credentials.
5. Commit and push from that clean worktree, then verify the remote branch SHA equals the local commit SHA. Leave the original dirty checkout's index and WIP untouched.

## Dashboard publication

- First prove pgAdmin locally via `curl -I http://127.0.0.1:<port>/`; a `302` to `/login` is a healthy response.
- Create the Cloudflare Access application and allow policy **before** adding a public hostname/tunnel route. Protect it with the user's identity provider and restrict origin exposure to loopback/tunnel-only.
- Keep dashboard credentials in the private env file. Never display them in chat, logs, diffs, or tool output. If a secret is accidentally emitted, rotate all affected credentials before continuing.
