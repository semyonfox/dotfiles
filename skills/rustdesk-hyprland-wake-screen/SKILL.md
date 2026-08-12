---
name: rustdesk-hyprland-wake-screen
description: "Use when wake/check Semyon's Hyprland PC displays over SSH when RustDesk has no image because the screen/DPMS is off; handle hyprlock still being locked."
version: 1.0.0
created_by: agent

metadata:
  harness: [hermes]
---

# RustDesk Hyprland Wake Screen

Use when Semyon says RustDesk shows black/no image after his PC monitors turned off, or asks to wake/check the screen remotely over SSH.

Target context:
- PC runs Hyprland/Wayland.
- RustDesk may lose image when displays are DPMS-off/asleep.
- Waking the display is different from unlocking the session: `hyprlock` may still be active after DPMS is on.

## Quick workflow

1. SSH to the PC using the known fleet alias if available, usually `pc`.
2. Identify the graphical user/session. Default user id is usually `1000`; verify if needed:

```bash
ssh pc 'id -u; loginctl list-sessions --no-legend'
```

3. Wake displays via Hyprland DPMS:

```bash
ssh pc 'export XDG_RUNTIME_DIR=/run/user/1000; hyprctl dispatch dpms on'
```

4. If `hyprctl` cannot find the instance, provide the Hyprland instance signature explicitly:

```bash
ssh pc 'export XDG_RUNTIME_DIR=/run/user/1000; export HYPRLAND_INSTANCE_SIGNATURE=$(ls -1 /run/user/1000/hypr | head -n1); hyprctl dispatch dpms on'
```

5. Check display/DPMS state:

```bash
ssh pc 'export XDG_RUNTIME_DIR=/run/user/1000; export HYPRLAND_INSTANCE_SIGNATURE=$(ls -1 /run/user/1000/hypr | head -n1); hyprctl monitors'
```

Look for monitors listed and not disabled. If RustDesk still has no image, the displays may be awake but the lockscreen/compositor capture path may still block useful viewing.

6. Check whether `hyprlock` is currently running:

```bash
ssh pc 'pgrep -a hyprlock || true'
```

If `hyprlock` is running, report that the screen may be awake but locked. Do **not** kill `hyprlock`, type passwords, or bypass the lock unless Semyon explicitly asks and the scope is clear.

## CLI connectivity test from Semyon's PC

When a remote RustDesk host has an approved unattended password and the goal is to prove a connection without manually entering its ID, use the existing graphical RustDesk client on `pc` over SSH. First obtain the remote ID privately (do not post it in a group channel), then run from a session with the graphical runtime variables:

```bash
ssh pc 'export XDG_RUNTIME_DIR=/run/user/1000; export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus; export DISPLAY=:0; rustdesk --connect <remote-id> --password <password>'
```

Verify the client window through Hyprland rather than trusting the command dispatch alone:

```bash
ssh pc 'export XDG_RUNTIME_DIR=/run/user/1000; export HYPRLAND_INSTANCE_SIGNATURE=$(find /run/user/1000/hypr -mindepth 1 -maxdepth 1 -type d -printf "%f\\n" | head -n1); hyprctl clients -j'
```

A RustDesk window titled `<remote-id> - Remote Desktop - RustDesk` confirms the session window opened. Close the test client afterward. Do **not** use `--password` for routine use: command-line arguments are visible to local process inspection while the client is running. Prefer the RustDesk password prompt for normal connections.

## Optional input-mimic fallback

If DPMS does not wake the RustDesk capture path, try a tiny synthetic input if `ydotool` is installed and its daemon is running:

```bash
ssh pc 'ydotool mousemove -x 1 -y 0'
```

If unavailable, install/setup only after approval because it touches system input injection:

```bash
sudo pacman -S ydotool
sudo systemctl enable --now ydotool
```

## Verification checklist

- `hyprctl dispatch dpms on` returned successfully.
- `hyprctl monitors` lists active monitors.
- `pgrep -a hyprlock` checked and lock state reported.
- If RustDesk still has no image, state whether this looks like DPMS sleep, `hyprlock`, portal/screencast, or framebuffer/display-detection issue.

## Notes and pitfalls

- `dpms on` wakes monitors; it does not unlock `hyprlock`.
- On Wayland, `xdotool` is usually the wrong tool. Prefer compositor commands or `ydotool`.
- A DisplayPort/HDMI dummy plug can be the reliable hardware fix if RustDesk loses framebuffer when physical monitors sleep/disconnect.
- Avoid broad Hyprland/session config rewrites for this symptom unless the quick wake/check flow fails repeatedly.
