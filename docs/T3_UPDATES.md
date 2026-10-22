# T3 nightly updates: custom headless deployment

The existing `t3-code-headless.service` remains the only backend on port 3773.
Its bind, access policy, HOME, userdata, worktrees and service identity are unchanged.
Do not install upstream `t3code.service` or start a second server against this data.

## Commands

```sh
~/bin/update-t3-nightly --check  # official latest nightly vs selected service runtime
~/bin/update-t3-nightly         # stage verified nightly, apply only when safely idle
systemctl --user start t3-nightly-update.service # same operation, journal logging
cat ~/.t3/update-headless/status
cat ~/.t3/update-headless/busy.json
journalctl --user -u t3-nightly-update.service
systemctl --user list-timers t3-nightly-update.timer
```

`--maintenance-stop` is a **manual, explicitly authorised interruption** path, not a scheduled force option. It records the native busy inventory, validates the same official payload and private rollback storage, and uses the existing T3-only systemd SIGINT stop. It requires MainPID=0 and SubState=dead before the same WAL-aware snapshot, integrity, migration and compaction-aware full-history checks. Schema-check errors still fail closed. Recovery still refuses to kill newly admitted candidate work. No SQL flags are cleared and no persistent busy-deferral setting is changed. The timer and ordinary `--apply` continue deferring active work by default. Use only after explicit approval to interrupt current work, not merely a generic maintenance approval.

`--check` does not download an archive, stop a service or change runtime selection.
It obtains public GitHub release metadata and updates only the local lock directory.
Both Bash and Zsh `update()` functions already use `~/.local/bin/update-ai-clis`.
On this custom-service host, that helper delegates its T3 step to this same updater;
`update-ai-clis --t3-dry-run` delegates to `--check`. The normal shell `update` still
updates other tools; use the scoped commands above for T3 alone.

## Schedule

`t3-nightly-update.timer` runs at **00:00, 03:00, 06:00, 09:00, 12:00,
15:00, 18:00 and 21:00 UTC**, with up to one minute scheduling accuracy and no
random delay. In Dublin summer time these are 01:00, 04:00, 07:00, 10:00,
13:00, 16:00, 19:00, 22:00. In winter Dublin time equals UTC. UTC avoids DST
interval surprises. `Persistent=true` catches up one missed run after downtime,
not every missed check. This is a systemd script job, not an agent/model run.
Systemd serializes this oneshot; `flock` also excludes simultaneous manual runs.
A download or validation failure returns nonzero, marks the unit failed and
retains `FAILED` or `RECOVERY REQUIRED` status. Busy deferral is not an update
success: the status explicitly says `DEFERRED`, and `pending` retains the version.

## One owner, not an npm illusion

The custom wrapper uses `~/.t3/runtime/headless-current/t3`. The pointer initially
selects the original October 5 runtime; changing the wrapper does not restart or
update the existing process. Only the updater switches this pointer after safety
checks and consistent backups. After a successful live deployment it also aligns
`~/.local/bin/t3` to that pointer. The previous npm launcher is saved as
`~/.t3/update-headless/previous-cli`; the npm package/prefix are not uninstalled.
Before that first deployment, npm and the server can still report different
versions. Never report a newer npm CLI as a deployed backend update.

Other machines without this custom lane retain owner-aware behavior: npm uses
its existing prefix and stable/nightly channel, native runtime launchers use
upstream `t3 update` without `--yes`, pacman stays package-managed, and unknown
or preview installations fail closed. No automatic channel migration.

## Preservation and failure behavior

1. Choose the newest published official non-draft **nightly** release, not the
   first GitHub entry (a preview may appear first). Pin its exact release asset
   URL/name, require its GitHub SHA256 digest, reject unsafe archive members,
   and execute `--version` on the unpacked candidate. Previously staged content
   is reusable only when its recorded complete file hashes still pass.
2. Require zero unfinished V2 runs, idle/closed/stopped native provider threads
   and ready/stopped provider sessions. Unresolved requests block only when their
   associated run is nonterminal or cannot be mapped. Historical prompts remain
   untouched; they are not proof of current work. Require a 30-second quiet
   interval and repeat immediately before the maintenance stop.
   Independently inspect the **entire** live descendant tree. Only the exact
   observed persistent transports are recognized: Claude stream-JSON, Codex
   app-server and its code-mode host, and the precise uv/Python Blender-MCP
   chain. This allowlist applies only alongside native-idle proof, never alone.
   Blender-MCP is a provider-owned transport, not the Blender application.
   An arbitrary shell, rsync/ssh, unknown MCP server, extra child of a recognized
   daemon, unreadable process or changed schema fails closed. Even a completed
   V2 run cannot override an outliving command. No SQL flags are cleared.
   Clients must not submit new work during the brief maintenance boundary:
   these repeated checks are not an atomic upstream admission/drain API.
3. Require rollback-destination space (two uncompressed active-DB copies plus
   2 GiB), without deleting existing recovery sets. By default use the local
   backup directory. Optional Stow config `~/.config/t3-nightly-update/backup-root`
   contains one absolute, existing, writable private directory owned by the user.
   This host uses `/mnt/media/backups/t3-nightly-server` on the existing NAS;
   missing/unwritable storage fails before a service stop, with no root fallback.
   After the repeated idle gate, stop only T3 and take **one** consistent snapshot
   using SQLite's WAL-aware backup API, then integrity-check it before switching.
   This avoids redundant online/stopped full copies and transient destination WAL
   duplication. If that pre-switch snapshot fails, restart the original runtime
   against its untouched original database, not the incomplete snapshot.
   No vacuum, pruning, arbitrary SQL rewrite or training/history export.
   The legacy `state.sqlite` remains untouched; live data is `userdata/statev2.sqlite`.
4. Restart only the existing custom T3 service. Check real process executable,
   its version, HTTP health and full canonical history preservation through a
   stable read transaction. The user approved upstream native compaction, not
   arbitrary deletion: the guard allows only the inspected supersession rules.
   Retain first/latest message/node anchors, reject unexplained unique removals
   and retained-event mutations, and compare all old projected message/tool/
   checkpoint/context/run payloads, not just IDs. Imported V1 event removal needs
   a completed native import marker and intact retained V1 transcript sources.
   Startup node/subagent cancellation and provider-session stop changes require
   matching appended canonical events and tightly bounded field/status changes;
   thread timestamp/PR-link changes likewise need their canonical event evidence.
   Runtime replay equivalence does not preserve every historical revision for
   training: original raw states remain in retained private recovery snapshots.
5. On a failed switch, stop the candidate, retain its entire failed database
   and sidecars under the backup, restore the consistent pre-switch database,
   previous pointer and preserved private local configuration copies, and check
   old-service health.
   Report recovery-required if recovery itself fails or new work prevents a safe
   rollback. An on-disk transaction marker blocks subsequent automatic attempts
   after interruption/incomplete recovery, including the already-current branch.
   No failed-state data is discarded; any writes
   admitted during candidate startup must be reconciled before discarding that
   retained state. This is release recovery, not manual event/migration editing.
6. Successful rollback snapshots are losslessly compressed. Old runtimes and
   backups are not pruned automatically. Disk pressure is a real failure, not
   something to hide by deleting history. Failed download stages remain for
   diagnosis; successful temporary public-release staging is removed.

By default backups live under `~/.t3/update-headless/backups/<UTC timestamp>-<version>/`.
With the private backup-root config they live under that directory instead;
the transaction/status records retain the exact path. Original local recovery
sets are never relocated or pruned by this setting.
Upstream nightly migrations are part of an approved deployment. Migration 63 in
`0.1.1-nightly.20261019.3373` removes unused V1 projection copies in `statev2`;
it is not a reason to run independent cleanup or assume binary-only rollback.
The backup and history-ID checks are required. Real migration and OAuth are
not verified merely by staging a candidate or passing fixture tests.

## Rollback / disable

### Deployment prerequisites (deployment lane, not fixture-test success)

- Retain the original task evidence, pre-edit copies and local private backups.
  Confirm existing Stow links, executable permissions, `curl`, `jq`, Python
  SQLite support, `flock`, GNU coreutils, gzip and user-systemd are available.
  Keep the same unit, HOME, bind/access policy, port and userdata/worktree paths.
- Re-resolve official latest nightly at deployment time, inspect exact-version
  release migrations for any state outside the protected DB/config set, and
  stop if its backup/recovery requirements exceed this lane. GitHub asset
  digest proves release/download identity, not application migration safety.
- Verify the previous executable still runs and configured rollback storage can
  retain both DB states. The SQLite snapshot includes WAL and is made once with
  T3 stopped, before pointer switch; a failed pre-switch snapshot restarts the
  untouched old DB. Monitor local WAL/free space during post-start verification.
  Configuration backups are private and must not enter task attachments.
  Confirm there is no unresolved transaction marker, then establish native idle
  and do not admit new UI/API work across the switch. Never override busy gates
  just because a maintenance restart was approved.
- Review rollback as a **data restore**, not a binary downgrade. The candidate
  may migrate immediately. Restore only in quiescent maintenance, preserve its
  DB/sidecars/config first and reconcile any post-start writes. Automatic
  recovery refuses to stop candidate-side new work and retains the marker if
  recovery fails. Old-process identity, version and HTTP are checked before
  declaring rollback recovered. There is no claim of migration/downgrade
  compatibility from isolated tests; deployment must observe real continuity.

The implementation task does not enable, install or reschedule units. An
existing timer may already be deployed from the owning card's prior attempt.
Deployment must read it back and deduplicate rather than create another job.
Scheduler interface is simply `~/bin/update-t3-nightly --apply`, noninteractive,
without any model call. Exit 0 includes CURRENT, UPDATED, DEFERRED and lock-skip;
inspect `status`/`pending` to distinguish outcomes. Nonzero means failure or
recovery-required. Manual, shell-helper and scheduler calls share the same lock.

To stop future checks without touching the live backend:

```sh
systemctl --user disable --now t3-nightly-update.timer
```

Before the first successful switch, the old runtime/data are unchanged. The
pre-edit wrapper/helper/docs are retained in the task evidence bundle. Restoring
those files does not require a backend restart. For a completed deployment,
first establish idle maintenance, disable the timer, read the chosen backup's
`previous-runtime`, preserve current DB/sidecars in a new recovery directory,
restore its `statev2.sqlite` (or decompress `statev2.sqlite.gz`), atomically
restore `headless-current`, then start **only** `t3-code-headless.service`.
Do not blindly repoint an old binary at a migrated database. Retain both DB
states and reconcile any post-deployment work; never silently throw it away.

## MCP remains a separate acceptance gate

The supported direction is root/default Hermes consuming
`http://127.0.0.1:3773/mcp` using external-client OAuth. Once an OAuth-capable
runtime is actually serving and metadata returns JSON, use the native custom
installer, not a handwritten `mcp_servers` entry:

```sh
hermes --profile default mcp add t3-code --url http://127.0.0.1:3773/mcp --auth oauth --connect-timeout 180
```

A human must approve **Read only** on the secure T3 authentication surface.
Do not reuse T3 provider-session bearer credentials or request codes/passwords
in chat. Saved config, authenticated tool inventory, an actual harmless T3
read and availability after a supported default-profile MCP reload/fresh
session are separate checks. MCP does not transplant personality, whole memory,
private conversations or skills; it is not reverse MCP, ACP or a model backend.

## Verification

```sh
bash -n server/bin/update-t3-nightly server/bin/t3-headless-run home/.local/bin/update-ai-clis
python3 tests/update-t3-nightly.py
python3 tests/update-t3-nightly-storage.py
python3 tests/t3-history-preservation.py
bash tests/update-ai-clis.sh
bash tests/update-shell-functions.sh
zsh -n home/.zsh_functions
systemd-analyze --user verify ~/.config/systemd/user/t3-nightly-update.{service,timer}
```

The new suite exercises isolated orchestration fixtures and real SQLite backup /
history-ID checks. It never starts a real backend or modifies canonical user data.
Live deployment, migrations, health and OAuth require their own observed output.

Sources:
- https://github.com/pingdotgg/t3code/releases
- https://github.com/pingdotgg/t3code/blob/v0.1.1-nightly.20261019.3373/apps/server/src/persistence/Migrations/063_DropUnusedV1Projections.ts
- https://github.com/pingdotgg/t3code/blob/main/docs/user/outside-agents.md
- https://hermes-agent.nousresearch.com/docs/user-guide/features/mcp
