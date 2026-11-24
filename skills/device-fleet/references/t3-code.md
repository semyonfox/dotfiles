# T3 Code Fleet Setup

Last refreshed: 2026-07-03 from `server` using non-sudo local and SSH probes.

## Key Rule

Verified 2026-11-01: `server` runs the native `t3code.service` (`t3 service install`, nightly, runtime under `~/.t3/runtime/versions`), replacing the custom `t3-code-headless.service`, which is disabled and must not be re-enabled. `~/.t3/service.env` holds only `T3CODE_LAN=true`; the default port 3773 is what the `t3.semyon.ie` tunnel uses. The `t3` CLI is the official install (`~/.local/bin/t3` symlink into the runtime). T3 finds harnesses through its login-shell PATH lookup (`os-jank.ts`), so no PATH drop-in or binary path setting is needed, and `/proc/<pid>/environ` does not show that lookup. npm harnesses live under `--prefix ~/.local`, because bare `npm -g` on `server` lands in `nvm/v24.22.1`, which is not on the login PATH. There is no update timer: Semyon updates from client apps (Settings → Environments or the sidebar update button). T3 Connect is on for `server` (relay `https://relay.t3.codes`, agent activity publishing off); laptop, PC and phone sign-in was still pending on this date. Everything below this section that describes the custom unit is history.

The server runs T3's native runtime (`~/.t3/runtime/versions/<ver>/t3`) under upstream `t3code.service`, which T3 writes and updates itself with `t3 update`. `~/.local/bin/t3` is a small sh launcher into the current runtime. User lingering is enabled, so the user service manager can start it without an interactive login.

The old custom `t3-code-headless.service`, its wrappers (`t3-headless-run`, `t3-headless-preflight`, `t3-headless-update`), the `update-headless` updater state and the npm `t3` install were removed on 2026-11-18. Older dated notes below mention them as history.

`t3 connect status` and other `t3` subcommands can run migrations on the live db even with a different version serving, so they are not read-only: on 2026-11-01 one moved live from migration 72 to 76. Use `t3 status`, or read the db, and do not run a newer CLI against live data to inspect it.

Do not tell agents to start Semyon's normal T3 Code with `npx t3@nightly serve`. That is a public quickstart pattern, not the verified fleet setup.

## `server`

### 2026-10-03 update: current runtime and desktop access

- Verified runtime and npm nightly: `0.0.46-nightly.20261003.2623`. The enabled `t3-code-headless.service` remains active on port 3773, with the existing public endpoint `https://t3.semyon.ie/` returning HTTP 200.
- Current binary resolves to `~/.local/lib/node_modules/t3/bin/t3.js`. Runtime state is in `~/.t3/userdata/statev2.sqlite`; retain `state.sqlite` and the legacy tables in the new database. Built-in migration completed 2,399 legacy threads and 100,770 user/assistant messages. Older reasoning/tool/plan records remain in legacy tables and are not new-format timeline items.
- PC and laptop both run the same nightly. Their encrypted `~/.t3/userdata/connection-catalog.json` points to HTTPS/WSS at `t3.semyon.ie`; the server environment must not appear in `disabledEnvironmentIds`. Both showed Connected and authenticated again after normal app restarts.
- Six old active sessions were revoked during reconnection. After explicit user approval, the new 30-day PC/laptop sessions were replaced by 365-day sessions at 14:00 UTC on October 3. Both native desktops authenticated through `t3.semyon.ie` with the replacement credentials, then their previous desktop sessions were revoked. The desktop expiry is October 3, 2027. Preferences and keybindings retained exact file hashes. Both Android sessions remain preserved: the original expires October 18, 2026 and the newer October 3 session expires November 2, 2026. Preserve the server signing state when maintaining access. Direct bearer sessions do not automatically renew.
- One-year credential provisioning used the desktop's exact Electron 44.4.2 runtime and protected `gnome_libsecret` backend to encrypt a fresh known server-only catalog while the desktop was closed. Its initial Linux encryption identity is the packaged name `t3code`; the later `T3 Code (Nightly)` display name selects a different key in a helper and cannot be substituted. No existing catalog was decrypted. Two unused test credentials were revoked after rollback, and the temporary native runtimes and obsolete opaque backups were removed after success. Receipt: `~/.local/state/t3-reconnect-20261003/one-year-credentials-result.json`. The saved scripts are specific to this repair and must not be rerun unchanged.
- Desktop preferences remain separate and keybindings are retained. Both have contrast 115, panel animations 100 ms, terminal font 12, collapsed diff files and word wrap. PC model favourites were reset, then the user's ten new PC choices were copied to the laptop after selection. Lists and order match. Final audit found the PC had reverted three display values after an earlier edit while its app was open; these were corrected while the app was closed. Both apps were fully restarted and authenticated again at 12:24 UTC for laptop and 12:26 UTC for PC. Laptop appearance controls and a native settings save verified the values and retained favourites. Other preferences remain separate: PC working shelf on and locale timestamps; laptop shelf off and 24-hour timestamps. Previous laptop favourites are backed up under `~/.local/state/t3-preferences-20261003/`; restart and preference backups are under `~/.local/state/t3-final-preferences-20261003/` on each desktop. PC launcher is `~/.local/bin/t3code-nightly`, selecting the newest AppImage under `~/.local/opt/t3code-nightly`; laptop launcher points to `~/Applications/T3-Code/T3-Code.AppImage`. For future preference changes use native settings, or close the app before editing its settings file; disk edits do not notify its cached renderer and an ordinary settings save writes the whole object.
- Final history audit found no undeleted desktop-only conversations absent from the server. Three missing active-thread PNG attachments were restored from the laptop's September 14 backup with exact size/SHA-256 checks and no overwrites. All 129 attachment references on 57 undeleted threads now resolve to files of the expected size. Desktop-only deleted threads and legacy details remain preserved rather than being resurrected.
- SnapShot is enabled on both Hyprland desktops. Actual captures through the registered native action succeeded on each; the installed Ctrl+Shift+2 binding calls `com.t3tools.T3Code:capture-window`. The PC's outdated capture helper was replaced from its current AppImage, retaining a backup under `~/.local/state/t3-preferences-20261003/`; both helpers now match their bundles and report feedback available. Test captures, draft attachments and temporary UI screenshots were removed. Light/dark palette choices remain unchanged. Evidence is `~/.local/state/t3-reconnect-20261003/snapshot-preferences-result.json`.
- Supported Android APK: `https://fileshare.semyon.ie/t3-apk.php`, built October 3 from `e8545b293b79`, version 2.0.0, package `com.t3tools.t3code.preview`, arm64. Package and signing certificate match the previous app. Install over the existing app to retain storage. User confirmed this APK is not installed yet; phone update, migration and public-domain connection confirmation remain outstanding. Existing watcher is `~/.hermes/scripts/t3code-mobile-watch.sh`, with dedicated checkout `~/t3code-mobile-work/t3code`; do not use the dirty contribution checkout for mobile builds.
- Non-secret verification receipts: `~/.local/state/t3-reconnect-20261003/`, `~/.local/state/t3-history-audit-20261003.md`, and `~/.local/state/t3-mobile-build-audit-20261003.md`.

### Related Units

- `t3code-hyperion.service`: disabled dev instance. The `t3code-hyperion` wrapper defaults to the canonical checkout at `/home/semyon/code/contribs/t3code`; its separate home is `/home/semyon/.t3-code-hyperion`, with server port `14773`, web port `6733`, and bind host `0.0.0.0`.
- `t3-session-archive.timer`: see below.

### Home Workspace Checkpoint Caveat

Verified 2026-08-01: the T3 project rooted at `/home/semyon` had 33 checkpoint
records, all already marked `missing`, and none resolved to a Git commit ref.
Repeated checkpoint attempts ran `git add -A` against the entire home tree,
timed out after 30 seconds, and accumulated 7.39 GB of unreachable objects in
an otherwise unborn `~/.git` repository. That stray home-level repository was
permanently removed after confirming it had no commits, remotes, refs, reflogs,
index, or tracked files. The separate `~/dotfiles/.git` repository was
unaffected, and T3 remained active.

### Safe Commands

Read-only:

```bash
systemctl --user status t3code.service --no-pager -l
systemctl --user cat t3code.service --no-pager
journalctl --user -u t3code.service -n 80 --no-pager
ss -ltnp 'sport = :3773'
```

Restarting or updating T3 kills jobs started inside a T3 session. Only on request, and from outside the T3 service cgroup.

## Server provider installation ownership, verified 2026-09-05

- Bash and Zsh use `~/.local/bin/update-ai-clis`, stowed from `home/.local/bin/update-ai-clis`.
- Codex and Gemini use npm under NVM Node 24.16.0. Claude uses its native `~/.local/share/claude/versions` installation; OpenCode uses `~/.opencode/bin/opencode`; Cursor uses native `cursor-agent`; Grok uses `~/.grok/bin/grok` through `~/.local/bin/grok`.
- Keep `agent` pointing to Cursor. Grok's official installer also writes `agent` and shell startup files. Invoke its installer/updater with `SHELL=/bin/false` and `~/.grok/bin` appended to the subprocess PATH, exposing only `grok` on the normal PATH.
- Cursor's update endpoint returned unauthenticated even after its public installer installed the current build. Account sign-in is still needed for that update path; do not claim installation verifies authentication.
- T3 has six built-in drivers: Codex, Claude, Cursor, Grok, OpenCode, Antigravity. Antigravity's installed ACP runtime is managed under `~/.t3/tools/antigravity-acp`; standalone `agy` is separate. Do not replace it with an npm package.
- `t3-headless-update` was removed on 2026-11-18. `update` and `update-ai-clis` no longer touch T3. It runs from its native runtime under upstream `t3code.service` and updates itself with `t3 update`.

## Other device audit

### Preview and proxy fully retired, verified 2026-09-18

User requested the original installation only, an incremental data merge, and
removal of experimental volumes/full backups. Normal T3
was active on 3773 with original direct Codex, Claude and OpenCode binary paths.
Proxy services disabled; ports 3774, 8317 and 8318 closed. Preview/proxy/test
containers, image tags, launchers and experimental data volumes removed.

Five missing messages across two existing threads were added as v1-compatible
`thread.message-sent` events in a stopped-service SQLite transaction. Normal
T3 was restarted and its own projector populated them. Exact text, IDs and
thread IDs were verified, plus HTTP 200. No existing messages were replaced.
Five native Codex logs and one Claude transcript were copied into the original
host `.codex/sessions` and `.claude/projects` without overwriting existing files.

Small merge record only: `~/.local/share/t3-preview-merge-20260918`, containing
five-message delta, inserted event IDs, affected thread metadata and verification.
The whole `~/t3-orchestrator-v2` staging tree, full SQLite snapshots, duplicate
recovery transcripts, source checkout and release artifacts were deleted after
verification, as were both named preview/proxy volumes and the retired native
gateway state/key/versioned binary. Original `~/.cli-proxy-api` logs remain.

`t3-session-archive.timer` remains enabled with no expiration/pruning. It now
captures only the main native logs, without any Docker dependency. Previously
archived preview records remain preserved. Storage is
`~/.local/share/t3-session-archive`; capture stops below 2 GiB free. Claude
retention is 36500 days; archival copies have no expiry. Same-disk storage does
not protect against disk failure.

Verified on 2026-07-03:

- `nas`: no `t3` binary, no T3 user units, no listener on `3773`, `14773`, or `6733`.
- `nas`: user linger was `Linger=no`.
- `pc`: no `t3` binary, no T3 user units, no listener on `3773`, `14773`, or `6733`.
- `pc`: user linger was `Linger=yes`.
- `laptop`: unreachable over `ssh semyon@100.127.128.15` during the second audit. An earlier same-day probe saw T3 Code listening on `0.0.0.0:3773`, but the startup mechanism was not verified. Re-audit before documenting or changing laptop T3 startup.

## Laptop T3 history merged into server, verified 2026-11-06

- The live server unit is `t3code.service` (the service launcher, runtime under `~/.t3/runtime/versions/<ver>/t3 serve`). The launcher auto-updates nightlies and restarts `t3 serve`, which kills background jobs started inside a T3 session, so run long jobs with `systemd-run --user`.
- 82 laptop-local threads (74 new, 8 replacing the 2026-11-01 inert recovery copies) were merged with `~/.local/state/t3-laptop-migration-20261106/apply_live.py`: offline swap, 61.6 s outage, migration ledger (80) and DDL untouched, 82/82 threads identical through the API, `quick_check` ok. Pre-merge database deleted 2026-11-07 on request. `rehearsal/` (47 GB) can be deleted.
- The laptop's local backend still exists in the desktop app. Its `~/.t3/userdata/statev2.sqlite*`, `state.sqlite*`, `logs/`, `attachments/` are safe to delete with the app closed (see `LAPTOP-DELETION-LIST.md`).

## Laptop and PC local T3 and Codex state cleared, verified 2026-11-06

- Both desktop apps were stopped and their local backends cleared: `~/.t3/userdata/statev2.sqlite*`, `state.sqlite*`, `logs/`, `attachments/`, usage caches, `~/.t3/caches`, and Codex `sessions`, `archived_sessions`, `history.jsonl`, `session_index.jsonl`, `log`, `shell_snapshots`, `logs_2`/`state_5`/`thread_history_1`/`goals_1`/`queue_1` sqlite. Kept: app, sign-ins, settings, Codex auth/config/skills/memories/plugins. Laptop freed 504 MB.
- Before deletion every Codex rollout, Claude project file, provider log and attachment was copied into the same paths on server (no overwrite, rechecked 0 missing). Snapshots, trace logs and Codex state tarballs are in `server:~/.local/share/t3-device-archive-20261106/{pc,laptop}`.
- Each desktop app starts a fresh empty local backend on launch. Threads started in the "local" environment land on that device again and show as doubles beside the server. Keep work on the server environment.
- The 2 laptop threads created after the morning merge were merged at 2026-11-06 23:27 UTC by `~/.local/state/t3-laptop-delta-20261106/apply_live.py` (frozen snapshot, `--skip-existing`, never replaces). 44.7 s outage, 2/2 identical through the API, live `quick_check` ok. A first attempt at 22:56 rolled back on a false search-probe failure (agent-launched threads have no indexed user message), fixed in that copy of `verify_merge.py`. Pre-merge database deleted 2026-11-07 on request. Two diverged laptop messages (thermal thread scheduled trigger, one Marker message) stay only in the archived snapshot.
- Strict dedup (identical role+text+attachments) found 544 copies: ~431 failed `preflight` workflow subagents ("session limit"), ~70 hourly Sentry triage runs, 2 import:codex copies. List is in `dedup-candidates.json` there. This build has no bulk thread delete (CLI has none, the app deletes one at a time over its authenticated socket), so nothing was deleted. On 2026-11-07 all 544 were archived instead (reversible, `t3_thread_organize` unarchive), 0 deleted, all 29 kept originals still live.

- Cleanup 2026-11-07, on request: all migration backups, snapshots, rehearsals and tooling deleted (`~/.local/state/t3-laptop-migration-20261106`, `t3-laptop-delta-20261106`, `~/.local/share/t3-device-archive-20261106`, `t3-laptop-archive-20261106`, the three `~/.t3/userdata/laptop-merge-*` copies). Verified first: all 84 laptop threads and 2,096 of 2,098 messages on server. The 2 not merged were the 20:00 benchmark trigger and a one-line "all done?" in the laptop copy of the Marker thread. Paths above under those folders no longer exist.

- open laptop cleanup / bw-audit work (2026-11-08): see `~/.local/state/laptop-cleanup-20261106/HANDOFF.md` on the server

## Laptop threads imported live, verified 2026-11-14

- 9 laptop-local threads (7 to 14 November) were imported with no outage into a new server project `Laptop` (`~/laptop-threads`, id `mcp:8732d96f-b30d-4ebb-b8e4-81adbec7708d`) as 10 `import:<provider>:<session>` threads. The notification-focus thread switched Claude to Codex, so it arrived as two threads.
- Method: copy the laptop's native Claude/Codex transcripts to the server (no overwrite, mtimes kept), rewrite only their `cwd` fields to the project root, then call the WS RPCs `agentSessions.scan` and `agentSessions.import {projectId, expectedWorkspaceRoot}` on `ws://127.0.0.1:3773/ws?orchestrationProtocol=2` with a short-lived `t3 auth session issue --scope orchestration:read --scope orchestration:operate` bearer, revoked afterwards.
- Limits: the importer skips anything under `~/.t3` (so never "No project"), only takes transcripts whose cwd is exactly the project root, uses a 30-day mtime window and caps at 100 transcripts. Threads cannot be moved between projects afterwards. It imports messages only: mid-turn steer messages and some interim assistant notes are not in native transcripts (dock thread lost 1 steer and 2 notes, DaVinci 3 notes). Laptop originals untouched.
## Laptop and server settings sync, verified 2026-11-14

- Server-level settings live in `~/.t3/userdata/settings.json` on each backend. The server watches that file and reloads it live, so a direct edit applies without a restart.
- Laptop `settings.json` now matches `server` apart from `deviceHosts` and `environmentIcon` (server only) and `grok` and `antigravity` being disabled, since neither is installed on the laptop. Pre-sync backup: `~/.local/state/t3-settings-sync-20261114/` on the laptop.
- `keybindings.json` held the same bindings on both, in a different order. `client-settings.json` and `desktop-settings.json` on `server` are stale leftovers from June and July (no desktop app runs there), so the laptop copies are the real ones and should not be synced.
