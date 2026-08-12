---
name: linux-wayland-session-autostart
description: "Use when a Wayland desktop app must start with its session."
version: 1.0.0
created_by: agent

metadata:
  harness: [hermes]
---

# Linux Wayland session autostart

Use when a user says a Wayland desktop application, launcher, panel, daemon, or companion process should start with Hyprland/UWSM but is absent, starts unreliably, has no session environment, or appears configured in one location while another configuration is active.

## Goal

Make the application start once, in the real graphical session, after the necessary Wayland/DBus environment exists. Do not solve it by merely starting the process over SSH or by adding competing launch routes.

## Principles

- The active compositor configuration is the source of truth. Do not assume `~/.config/hypr/hyprland.conf` is active merely because it exists.
- Modern Hyprland setups can use Lua configuration or generated configuration in parallel with legacy `.conf` files. A setting in a stale file is not a fix.
- A user systemd unit and compositor startup callback can complement one another: systemd manages lifecycle; the compositor callback starts/restarts it only after importing the graphical environment.
- Treat a unit running now as a baseline, not proof it will launch at the next login.
- Prefer `systemctl --user restart <app>.service` for a packaged user daemon rather than a second direct `app server --replace` process.
- Preserve existing wrappers and environment shims; inspect before changing them.

## Discovery

1. **Find the real desktop host.** If operating remotely, inspect `~/.ssh/config`, connect with `BatchMode=yes` and a bounded timeout, and distinguish the agent host from the graphical PC.
2. **Establish the session.** Capture the graphical user session and systemd user environment: `XDG_RUNTIME_DIR`, `WAYLAND_DISPLAY`, `HYPRLAND_INSTANCE_SIGNATURE`, `DBUS_SESSION_BUS_ADDRESS`, and `XDG_CURRENT_DESKTOP`.
3. **Inspect the application lifecycle.** Record binary/package origin, `.desktop` entry, user systemd unit, active/inactive state, main PID, restart count, current-boot journal, and any duplicate processes.
4. **Identify active configuration, not candidate configuration.** For Hyprland, inspect runtime bindings via `hyprctl binds -j` using the captured graphical session environment; check `hyprctl configerrors`; inspect the compositor startup wrapper; and search `.conf` and `.lua` sources for the application, startup handlers, and shortcut. A live binding with `dispatcher: "__lua"` is evidence that Lua is the effective config path.
5. **Check for conflicts.** Count live bindings for the shortcut, count application server processes, and locate every direct launch command, XDG autostart entry, and unit relation. Do not call source-file entries a conflict unless both execute in the active session.

## Correct start ordering

For an application that needs the Wayland session:

1. compositor begins;
2. export/import `WAYLAND_DISPLAY` and `XDG_CURRENT_DESKTOP` into the user manager;
3. start or restart the app's user service;
4. verify it owns a Wayland layer/window and responds to its client command.

In a Lua Hyprland config, put the service action in the `hyprland.start` command list immediately after environment import:

```lua
"systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
"systemctl --user restart example-launcher.service", -- after session env import
```

Use the exact service discovered on the host.

## Persistent systemd relation

If the packaged unit has `[Install] WantedBy=graphical-session.target`, enable it for the user and verify the generated wants link resolves to the package unit. This gives a second lifecycle path, but does not replace compositor-side environment ordering where the daemon needs Wayland variables.

After creating enablement during an active session, the active target might not show the new relation in every property dump until its next activation. Verify the link itself and `systemctl --user list-dependencies graphical-session.target`; do not disrupt the live graphical target merely to force proof.

## Safe change and verification

1. Back up the active configuration file with a timestamp.
2. Apply one exact, unique edit. For Lua, run `luac -p` when available.
3. Restart only the application service now; do not restart Hyprland or end the desktop session merely to test autostart.
4. Reload only the live Hyprland configuration (`hyprctl reload`) after repairing a file that was missing when the compositor started. Then require `hyprctl configerrors` to be empty: restoring the disk file alone does not clear the running compositor's retained error state.
5. Verify the service is active/running with zero unexpected restarts; only one server process exists; its client command works; Hyprland reports its window/layer; and the shortcut occurs exactly once in `hyprctl binds -j`. For an important bind, also resolve and test its referenced executable/helper path—registration alone does not prove the action works.
6. Report current verification and next-login persistence separately. Do not claim a full logout/login test unless it occurred.

## Missing Stow-managed Lua source

A live Hyprland Lua path can become a **dangling symlink** when its Stow source was created as untracked local work and omitted from a later checkout update. Treat this as source recovery, not an opportunity to replace the desktop configuration:

1. Prove the failure: `test -L ~/.config/hypr/hyprland.lua && test ! -e ~/.config/hypr/hyprland.lua`, then identify its intended dotfiles source from the link target.
2. Inspect Git status and stash/worktree history before creating a new configuration. A stash created with `--include-untracked` stores untracked source files in its third parent (`stash@{0}^3`); inspect that tree for the missing Lua source and related override modules.
3. Restore only the named source files into the dotfiles checkout. Do not apply the whole stash or overwrite unrelated configuration.
4. Validate each restored Lua module with `luac -p`. Recover and validate **every locally referenced dependency** that belongs to the same Stow package—especially helper scripts and override modules. For shell helpers, run `bash -n`, preserve executable mode, and use `readlink -f` plus `test -x` against the live runtime path before declaring a shortcut repaired.
5. Commit and push only the recovered source files, then prove deployed symlinks resolve to non-empty files. If the compositor is already running, reload its configuration and require an empty `hyprctl configerrors` result.
6. Do not restart Hyprland merely to prove file restoration. Validate the live compositor only in the actual graphical session and report next-login/reload validation separately.

## Session-detached GUI recovery

A desktop app launched through a remote shell can survive without a usable graphical-session attachment. Treat a running PID as insufficient evidence that the app is visible or controllable.

1. Inspect the app's process, current log, and Hyprland client list using the **user systemd manager's** `WAYLAND_DISPLAY`, `XDG_RUNTIME_DIR`, and `HYPRLAND_INSTANCE_SIGNATURE` values.
2. If it has no mapped Hyprland client and the user authorises termination, stop only that named stale process; then remove only its known stale CLI/IPC socket if the process is gone.
3. Relaunch through the live UWSM graphical session with explicit absolute paths and captured environment, for example `systemd-run --user --scope /usr/bin/uwsm app -- /usr/bin/<app> --new <workspace>`.
4. Verify all three before reporting success: a fresh app PID, a fresh-render/launch log line, and a mapped, non-hidden Hyprland client on a real workspace.

Do not infer failure from a missing binary merely because a remote launch was invisible. Do not kill a possibly interactive editor without explicit user approval, since it may hold unsaved buffers.

## Pitfalls

- **Wrong config file:** adding `exec-once` to legacy `hyprland.conf` does nothing if the active runtime binding comes from Lua.
- **Manual-start illusion:** `systemctl --user start` proves the daemon can run, not that Hyprland launches it after login.
- **Raw SSH GUI launch:** bare SSH lacks the relevant Wayland session context.
- **Duplicate daemons:** do not add a direct `server --replace` command when a packaged user service already owns it.
- **Destructive testing:** do not restart the compositor, user manager, or graphical target while the user is working.
- **Benign warnings:** classify unrelated warnings separately; do not wipe state/configuration without evidence.

## Reference

See `references/hyprland-vicinae-lua-startup.md` for a representative diagnosis and remediation.
