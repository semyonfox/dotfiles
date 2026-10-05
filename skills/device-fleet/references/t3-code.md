# T3 Code Fleet Setup

Last refreshed: 2026-07-03 from `server` using non-sudo local and SSH probes.

## Key Rule

Do not tell agents to start Semyon's normal T3 Code with `npx t3@nightly serve`. That is a public quickstart pattern, not the verified fleet setup.

The verified setup on `server` is an installed global `t3` CLI wrapped by user systemd units and helper scripts. User lingering is enabled, so the user service manager can start services without an interactive login.

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

- Installed binary: `/home/semyon/.local/bin/t3`.
- Symlink chain: `/home/semyon/.local/bin/t3` -> `/home/semyon/.nvm/versions/node/v24.16.0/bin/t3` -> `../lib/node_modules/t3/dist/bin.mjs`.
- Installed package: global npm `t3@0.0.29-nightly.20260630.690`.
- Runtime version output: `t3 v0.0.29-nightly.20260630.690`.
- User linger: `loginctl show-user semyon -p Linger` returned `Linger=yes`.
- Service: `t3-code-headless.service`.
- Unit path: `/home/semyon/.config/systemd/user/t3-code-headless.service`.
- Unit state: enabled and active on 2026-07-03.
- Startup target: `default.target` through `/home/semyon/.config/systemd/user/default.target.wants/t3-code-headless.service`.
- Listen port: `0.0.0.0:3773`.
- Base dir: `/home/semyon/.t3-code`.
- Working directory/project root for service: `/home/semyon`.
- Wrapper: `/home/semyon/bin/t3-headless-run`.
- Preflight guard: `/home/semyon/bin/t3-headless-preflight`.
- Lock: `/home/semyon/.t3-code/t3-headless.lock` via `/usr/bin/flock`.

### Service Unit

Source: `systemctl --user cat t3-code-headless.service`, 2026-07-03.

```ini
[Unit]
Description=T3 Code headless backend (single instance)
Documentation=https://github.com/pingdotgg/t3code/blob/main/docs/user/remote-access.md
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=300
StartLimitBurst=3

[Service]
Type=simple
WorkingDirectory=/home/semyon
Environment=HOME=/home/semyon
Environment=PATH=/home/semyon/.local/bin:/home/semyon/.nvm/versions/node/v24.16.0/bin:/usr/local/bin:/usr/bin:/bin
Environment=T3CODE_HOME=/home/semyon/.t3-code
Environment=T3CODE_NO_BROWSER=1
Environment=T3CODE_HOST=0.0.0.0
Environment=T3CODE_PORT=3773
ExecStartPre=/home/semyon/bin/t3-headless-preflight
ExecStart=/home/semyon/bin/t3-headless-run
Restart=on-failure
RestartSec=10
KillSignal=SIGINT
TimeoutStopSec=30

[Install]
WantedBy=default.target
```

### Wrapper Behavior

`/home/semyon/bin/t3-headless-preflight`:

- Uses `T3CODE_PORT`, defaulting to `3773`.
- Uses `T3CODE_HOME`, defaulting to `/home/semyon/.t3-code`.
- Refuses to start if another `t3 serve` process is already running.
- Refuses to start if TCP port `3773` is already listening.
- Creates the base dir.

`/home/semyon/bin/t3-headless-run`:

- Exports `HOME=/home/semyon`.
- Exports `T3CODE_HOME=/home/semyon/.t3-code`.
- Exports `T3CODE_NO_BROWSER=1`.
- Exports `T3CODE_PORT=3773`.
- Exports `T3CODE_HOST=0.0.0.0`.
- Runs:

```bash
/usr/bin/flock -n /home/semyon/.t3-code/t3-headless.lock \
  /home/semyon/.local/bin/t3 serve \
    --host 0.0.0.0 \
    --port 3773 \
    --base-dir /home/semyon/.t3-code \
    --no-browser \
    /home/semyon
```

### Related Units

- `t3-code-headless-update.path`: exists at `/home/semyon/.config/systemd/user/t3-code-headless-update.path`, but was disabled and inactive on 2026-07-03. It watches T3 CLI paths and triggers `t3-code-headless-restart.service`.
- `t3-code-headless-restart.service`: static oneshot that runs `systemctl --user try-restart t3-code-headless.service`.
- `t3code-hyperion.service`: exists for a dev instance but was disabled and inactive on 2026-07-03.
- The legacy-named `t3code-hyperion` wrapper now defaults to the canonical checkout at `/home/semyon/code/contribs/t3code`; its separate home remains `/home/semyon/.t3-code-hyperion`, with server port `14773`, web port `6733`, and bind host `0.0.0.0`.

### 2026-08-24 update: paths changed

The service is still `t3-code-headless.service` (enabled, active), but the
current wrapper `/home/semyon/bin/t3-headless-run` uses lock
`/home/semyon/.t3/t3-headless.lock` and no longer passes `--base-dir`; the old
`~/.t3-code` tree is gone and runtime state now lives under `~/.t3/userdata`
(including `state.sqlite`, which projects T3 threads/messages; provider event
logs under `~/.t3/userdata/logs/provider/events.<threadId>.log`). T3 now runs an
internal `opencode serve` child process. Thread IDs in T3 map to opencode
session IDs (`ses_...`) recorded in the event logs and in
`~/.local/share/opencode/opencode.db`.

### Home Workspace Checkpoint Caveat

Verified 2026-08-01: the T3 project rooted at `/home/semyon` had 33 checkpoint
records, all already marked `missing`, and none resolved to a Git commit ref.
Repeated checkpoint attempts ran `git add -A` against the entire home tree,
timed out after 30 seconds, and accumulated 7.39 GB of unreachable objects in
an otherwise unborn `~/.git` repository. That stray home-level repository was
permanently removed after confirming it had no commits, remotes, refs, reflogs,
index, or tracked files. The separate `~/dotfiles/.git` repository was
unaffected, and `t3-code-headless.service` remained active.

### Safe Commands

Read-only:

```bash
systemctl --user status t3-code-headless.service --no-pager -l
systemctl --user cat t3-code-headless.service --no-pager
systemctl --user show t3-code-headless.service --no-pager -p ActiveState -p SubState -p UnitFileState -p ExecStart -p FragmentPath
journalctl --user -u t3-code-headless.service -n 80 --no-pager
ss -ltnp 'sport = :3773'
```

Mutating, use only when explicitly asked:

```bash
systemctl --user restart t3-code-headless.service
systemctl --user enable --now t3-code-headless.service
systemctl --user disable --now t3-code-headless.service
```

## Server provider installation ownership, verified 2026-09-05

- Bash and Zsh use `~/.local/bin/update-ai-clis`, stowed from `home/.local/bin/update-ai-clis`.
- Codex and Gemini use npm under NVM Node 24.16.0. Claude uses its native `~/.local/share/claude/versions` installation; OpenCode uses `~/.opencode/bin/opencode`; Cursor uses native `cursor-agent`; Grok uses `~/.grok/bin/grok` through `~/.local/bin/grok`.
- Keep `agent` pointing to Cursor. Grok's official installer also writes `agent` and shell startup files. Invoke its installer/updater with `SHELL=/bin/false` and `~/.grok/bin` appended to the subprocess PATH, exposing only `grok` on the normal PATH.
- Cursor's update endpoint returned unauthenticated even after its public installer installed the current build. Account sign-in is still needed for that update path; do not claim installation verifies authentication.
- T3 has six built-in drivers: Codex, Claude, Cursor, Grok, OpenCode, Antigravity. Antigravity's installed ACP runtime is managed under `~/.t3/tools/antigravity-acp`; standalone `agy` is separate. Do not replace it with an npm package.
- Removed duplicate NVM npm packages for Claude and T3. NVM bin compatibility symlinks now lead to the retained native Claude and `~/.local` npm T3, preserving `/usr/local/bin` callers. Provider data directories were not removed.
- `~/bin/t3-headless-update` now points to the stowed `server/bin/t3-headless-update`. The old script is retained as `~/bin/t3-headless-update.before-provider-switchover-20260905`.
- Disabled `t3-code-headless-update.path` to avoid mid-install restarts. The explicit updater restarts only on a version change and checks service/port readiness. Invoke it outside the T3 service cgroup. No T3 restart was performed during this migration.

## Server update and recovery, verified 2026-10-04

- Server T3 is `0.0.46-nightly.20261004.2657`, updated from `0.0.46-nightly.20261003.2623` through `~/bin/t3-headless-update` after explicit update/restart approval.
- The updater ran outside the T3 service cgroup and restarted `t3-code-headless.service` once at 22:15:45 UTC. Service and port readiness passed; the monitor turn resumed automatically.
- Startup recovery cleared orphaned runs. Five top-level continuations were automatic; eight remaining original owners received literal `resume` through the authenticated laptop composer. Other externally continued threads were left alone. The existing Irish Rail production-merge approval hold was preserved.
- Recovery receipts are in `~/.t3/scratch/2026-10-03-monitor-all-running-t3-code-18c74860/t3-update-receipt.json` and `post-update-recovery.json`. No direct database writes, authentication bypass, custom source deployment, or recurring schedule were used.

## Other device audit

### Preview and proxy fully retired, verified 2026-09-18

User requested the original installation only, an incremental data merge, and
removal of experimental volumes/full backups. Normal `t3-code-headless.service`
is active on 3773 with original direct Codex, Claude and OpenCode binary paths.
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
