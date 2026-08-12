# T3 Code Fleet Setup

Last refreshed: 2026-07-03 from `server` using non-sudo local and SSH probes.

## Key Rule

Do not tell agents to start Semyon's normal T3 Code with `npx t3@nightly serve`. That is a public quickstart pattern, not the verified fleet setup.

The verified setup on `server` is an installed global `t3` CLI wrapped by user systemd units and helper scripts. User lingering is enabled, so the user service manager can start services without an interactive login.

## `server`

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
- `t3code-hyperion` wrapper defaults: repo `/home/semyon/code/personal/t3code-hyperion`, home `/home/semyon/.t3-code-hyperion`, server port `14773`, web port `6733`, bind host `0.0.0.0`.

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

## Other Devices

Verified on 2026-07-03:

- `nas`: no `t3` binary, no T3 user units, no listener on `3773`, `14773`, or `6733`.
- `nas`: user linger was `Linger=no`.
- `pc`: no `t3` binary, no T3 user units, no listener on `3773`, `14773`, or `6733`.
- `pc`: user linger was `Linger=yes`.
- `laptop`: unreachable over `ssh semyon@100.127.128.15` during the second audit. An earlier same-day probe saw T3 Code listening on `0.0.0.0:3773`, but the startup mechanism was not verified. Re-audit before documenting or changing laptop T3 startup.
