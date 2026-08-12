# Mobile stale shell snapshot replay

Use this when Semyon reports that the T3 Code mobile app stops showing new threads/updates past some point while the server backend is still running.

## Symptom

- Mobile thread list appears frozen/stale after a particular date/point.
- `t3-code-headless.service` is healthy and the server DB contains newer `projection_threads` rows.
- The APK endpoint may still be serving a recent build, so the failure is not necessarily the build watcher.

## Fast checks

```bash
systemctl --user show t3-code-headless.service -p ActiveState -p SubState -p MainPID -p NRestarts --no-pager
curl -fsS --max-time 5 http://127.0.0.1:3773/.well-known/t3/environment
python3 - <<'PY'
import sqlite3
DB='/home/semyon/.t3/userdata/state.sqlite'
con=sqlite3.connect(f'file:{DB}?mode=ro', uri=True)
cur=con.cursor()
for q in [
  "select count(*) from projection_threads",
  "select count(*) from orchestration_events",
  "select max(updated_at), max(latest_user_message_at) from projection_threads where deleted_at is null and archived_at is null",
]:
  print(cur.execute(q).fetchone())
print('latest active threads')
for row in cur.execute("""
  select thread_id,title,created_at,updated_at,latest_user_message_at,deleted_at,archived_at
  from projection_threads
  where deleted_at is null and archived_at is null
  order by updated_at desc
  limit 15
"""):
  print(row)
con.close()
PY
```

If the server has newer rows than mobile shows, suspect client shell-cache replay.

## Likely cause

The mobile client caches an `OrchestrationShellSnapshot` and reconnects by calling `subscribeShell` with `afterSequence`. If the phone's cached sequence is very old and the event log is large, the server replays every shell-relevant event after that sequence before the client reaches current state. With a large `orchestration_events` table this can look like a hard cutoff: the app is alive, but stuck catching up.

This is especially plausible when the DB contains huge append-only streaming volume such as many `thread.message-sent` rows. Prior `tool.updated` cleanup does not address `thread.message-sent` streaming chunks.

Useful counts:

```bash
python3 - <<'PY'
import sqlite3
con=sqlite3.connect('file:/home/semyon/.t3/userdata/state.sqlite?mode=ro', uri=True)
cur=con.cursor()
print('DB events by date')
for r in cur.execute("select substr(occurred_at,1,10), count(*), min(sequence), max(sequence) from orchestration_events group by 1 order by 1 desc limit 14"):
  print(r)
print('event types since high-water mark')
for r in cur.execute("select event_type, count(*), min(sequence), max(sequence) from orchestration_events group by event_type order by count(*) desc limit 20"):
  print(r)
con.close()
PY
```

## User-facing quick fix

Tell Semyon to force a cold mobile cache:

1. Force-close T3 Code.
2. Clear the Android app storage/cache, or uninstall/reinstall the latest APK from `https://fileshare.semyon.ie/t3-apk.php`.
3. Re-pair if required.

This makes mobile fetch a fresh shell snapshot instead of replaying a stale delta.

## Proper code fix to propose/patch upstream

The robust fix is a **server-side stale-cursor guard** in shell subscription/sync:

1. In `apps/server/src/ws.ts`, at `ORCHESTRATION_WS_METHODS.subscribeShell`, retain the existing live subscription + scope-bound queue before any catch-up work so events published during synchronization are not lost.
2. For a supplied `afterSequence`, call `projectionSnapshotQuery.getSnapshotSequence()`.
3. If `snapshotSequence - afterSequence` exceeds a bounded threshold (10,000 was validated against Semyon's multi-million-event DB), send `getShellSnapshot()` as the first stream item and then continue with the live stream; **do not call** `readEvents(afterSequence, Number.MAX_SAFE_INTEGER)`.
4. Keep the normal small-delta replay unchanged and continue to dedupe overlapping events client-side.
5. Add a websocket seam regression test that makes `readEvents` fail, supplies an over-threshold cursor, and asserts the first item is `{ kind: "snapshot" }`. This proves the fallback avoids the unbounded path.

A client-side cache-expiry policy is optional hardening, but is not required for compatibility: existing clients already understand `snapshot` stream items. The deployed backend must be rebuilt/reinstalled and restarted; changing the mobile APK alone does not activate this server-side guard.

Relevant code paths observed in the July 2026 tree:

- Client shell cache/replay: `packages/client-runtime/src/state/shell.ts`
- Mobile cache store: `apps/mobile/src/connection/environment-cache-store.ts`
- Server shell subscription replay: `apps/server/src/ws.ts`, `ORCHESTRATION_WS_METHODS.subscribeShell`
- Server shell snapshot query: `apps/server/src/orchestration/Layers/ProjectionSnapshotQuery.ts`

## Validation and rollout boundary

Run the focused server seam test, then the repository gates required by `AGENTS.md`:

```bash
./node_modules/.bin/vp test apps/server/src/server.test.ts
./node_modules/.bin/vp check
./node_modules/.bin/vp run typecheck
./node_modules/.bin/vp run lint:mobile
```

Before claiming the live issue is repaired, inspect the installed server bundle and current systemd command, then explicitly obtain authorization before replacing/restarting the persistent headless backend. A clean source checkout and passing test suite are not deployment evidence.

## Local hotfix deployment and mobile rebuild

When this is a confirmed stale-cursor replay problem, **waiting is not a fix**. A client stuck behind millions of events can remain apparently frozen for an impractical length of time. Deploy the server guard, then force-close/reopen the mobile app so it resubscribes; clearing app storage/re-pairing is the fallback if it still retains a bad cache.

### Server hotfix from a checkout

The user-local `t3` CLI may be an npm-installed bundle rather than the source checkout. Building the checkout alone does not change the running service.

1. Run the focused server test plus `vp check` and `vp run typecheck` first.
2. Build `apps/server` with `./node_modules/.bin/vp run --filter t3 build:bundle`.
3. Resolve the actual launcher with `readlink -f ~/.local/bin/t3`; its package root is the parent of `dist/bin.mjs`.
4. Stop the user service, timestamp-backup the installed `dist/`, copy every file from `apps/server/dist/` into that installed `dist/`, then start the service. Use `systemctl --user daemon-reload` if systemd reports changed units.
5. Verify the installed bundle contains a semantic marker from the guard (for example `Failed to determine orchestration shell replay range`), then verify `t3-code-headless.service`, the loopback environment endpoint, and `https://t3.semyon.ie/`.

Keep the hotfix source diff somewhere durable or upstream it: the normal `npm install -g t3@nightly` path will overwrite an installed-bundle hotfix.

### Rebuilding the APK deliberately

The mobile build watcher intentionally hard-resets its checkout to upstream. Before forcing a rebuild while the checkout holds a server hotfix, save `git diff --binary` outside the checkout and reapply it after the watcher completes. Do not confuse a fresh APK with the server fix: the stale-cursor guard is server-side and existing clients already understand the `snapshot` stream item.

To force the watcher to rebuild the same upstream SHA only when explicitly requested, back up its `last_success_*` state files, remove the active success keys, run `~/.hermes/scripts/t3code-mobile-watch.sh`, then verify the versioned artifact and both public mirrors with SHA-256. Verify the actual download URL too, not just files on disk.

## Build watcher gotcha

Do not confuse this with APK publication. Verify served APK and build state separately:

```bash
curl -kIsS --max-time 10 https://fileshare.semyon.ie/t3-apk.php | sed -n '1,20p'
sha256sum /home/semyon/t3code-mobile-builds/*.apk /home/semyon/server-stacks/fileshare/public-apk/t3-code-preview.apk 2>/dev/null || true
cat /home/semyon/.hermes/t3code-mobile-watch/last_success_sha 2>/dev/null || true
npm view t3 dist-tags --json
```

The watcher may intentionally serve a branch build or latest successful APK while a newer tag build failed. If a newer build failed with Gradle `OutOfMemoryError`, that is a build-pipeline issue, not proof that the thread sync bug is in the published APK.
