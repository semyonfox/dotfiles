---
name: remote-development-workflows
description: "Open, inspect, and support remote development workspaces through SSH and a user's graphical editor."
version: 1.0.0
created_by: agent

metadata:
  harness: [hermes]
---

# Remote development workflows

Use when Semyon asks to open a remote project in Zed or another editor running on one of his machines, or asks for an agent-supported practice workspace that he edits remotely.

## Core principle

Distinguish the **host where the agent is running** from the **graphical machine where the editor should open**. A headless host lacking a GUI session or local editor binary does not establish that the user's desktop editor is unavailable. Before saying an editor cannot be opened, inspect the user's SSH aliases and test the intended PC host.

## Safe workflow

1. Create or inspect the project at its requested remote path. For learning exercises, keep the scaffold tiny: source file, deterministic tests, and one run command.
2. Read `~/.ssh/config` for an explicit PC/desktop alias. Do not guess an IP or alter SSH configuration.
3. SSH with `BatchMode=yes` and a bounded `ConnectTimeout`; verify the editor CLI exists on that host with `command -v <editor>` and inspect its `--help` for the supported open-path invocation.
4. If SSH lacks GUI variables, identify the logged-in graphical user session with `loginctl` and launch through the user systemd/Wayland session rather than trying to export the headless SSH environment directly. On Hyprland/UWSM systems, a suitable shape is:

   ```bash
   XDG_RUNTIME_DIR=/run/user/<uid> \
   DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/<uid>/bus \
   systemd-run --user --scope --quiet uwsm app -- zed -n /absolute/project/or/file
   ```

   Use the actual user id and project path discovered during the session. `-n` opens a new workspace; omit it only when the user explicitly wants the current Zed window reused.
5. Verify the outcome over SSH: check for the editor process and, where available, a matching `journalctl --user` start entry. Report the exact opened path, not private session internals.

## Zed-specific notes

- `zed /path` opens a project or file; `zed -n /path` makes a new workspace; `zed -e /path` targets an existing Zed window.
- A test repository may intentionally begin red because the target function is blank. State this plainly: it proves the runner and test discovery are working, not that the learner failed.
- For an agent-assisted learning loop, preserve the learner's ownership: let Semyon edit the source, then read the exact edited file and run its tests when he says to check it. Explain the smallest relevant failure before supplying a solution.

## Pitfalls

- Do not install GUI editor packages or change remote-editor configuration merely because `zed` is absent on the agent's current host.
- Do not use the unique link of a timed hiring assessment to discover its contents if it may begin the assessment.
- Do not launch an editor on an unrelated SSH host. Confirm the configured desktop alias first.
- Avoid broad boilerplate repositories for interview-assessment prep. One exercise at a time with runnable tests is more useful for a rusty candidate.
