# RustDesk unattended access on Hyprland/Wayland

Use when RustDesk connects to Semyon's Hyprland desktop but the viewer sees:

```text
Wayland
Please select the screen to be shared(Operate on the peer side).
```

## Cause

RustDesk on Wayland uses XDG Desktop Portal / `xdg-desktop-portal-hyprland` for screen capture. The default Hyprland share picker is interactive and appears on the controlled machine, which breaks unattended access.

RustDesk upstream also states Wayland unattended access is experimental; switching to X11 would avoid the picker but is heavier and may require package/session changes. For Semyon's Hyprland PC, prefer the XDPH custom picker workaround first.

## Fix pattern

1. Confirm the target host/session:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=6 pc 'hostname; pgrep -a rustdesk; pgrep -a Hyprland; systemctl --user is-active xdg-desktop-portal-hyprland xdg-desktop-portal || true'
```

2. Get the active Hyprland instance for SSH-launched commands:

```bash
export XDG_RUNTIME_DIR=/run/user/1000
export HYPRLAND_INSTANCE_SIGNATURE=$(basename /run/user/1000/hypr/* | tail -n1)
hyprctl monitors -j
```

3. Install a non-interactive XDPH picker at `~/.local/bin/hyprland-rustdesk-autopicker` that prints the Hyprland share-picker stdout contract:

```text
[SELECTION]r/screen:<monitor-name>
```

A robust picker should:

- infer `XDG_RUNTIME_DIR=/run/user/<uid>`
- infer `HYPRLAND_INSTANCE_SIGNATURE` from `/run/user/<uid>/hypr/` when SSH lacks the graphical environment
- call `hyprctl monitors -j`
- choose the focused active monitor, then fall back to known monitors such as `DP-2` or `HDMI-A-2`
- print `r` when invoked with `--allow-token`
- log selections under `~/.local/state/`

4. Configure XDPH in `~/.config/hypr/xdph.conf`:

```ini
screencopy {
    allow_token_by_default = true
    custom_picker_binary = /home/semyon/.local/bin/hyprland-rustdesk-autopicker
}
```

5. Restart portal services and RustDesk user processes:

```bash
systemctl --user restart xdg-desktop-portal-hyprland xdg-desktop-portal
pkill -u semyon -f '/usr/share/rustdesk/rustdesk --server' || true
pkill -u semyon -f '/usr/share/rustdesk/rustdesk --tray' || true
sleep 2
pgrep -a rustdesk
```

## Verification

```bash
~/.local/bin/hyprland-rustdesk-autopicker --allow-token
systemctl --user is-active xdg-desktop-portal-hyprland xdg-desktop-portal
pgrep -a rustdesk
rustdesk --get-id 2>/dev/null || /usr/share/rustdesk/rustdesk --get-id 2>/dev/null
```

Expected picker output:

```text
[SELECTION]r/screen:<monitor-name>
```

If the mobile/client side still shows the old dialog immediately after the fix, have Semyon fully close the failed RustDesk attempt and start a fresh connection; the old session can cache the failed portal attempt.

## Pitfalls

- SSH sessions usually do not inherit `HYPRLAND_INSTANCE_SIGNATURE`, so `hyprctl` will say `HYPRLAND_INSTANCE_SIGNATURE not set!` unless you export it.
- Do not persist a claim that laptop/PC SSH is broken from one route failure; try known aliases and Tailscale/LAN fallbacks first.
- The picker is security-reducing by design: it grants screen sharing non-interactively. Use it only on Semyon's own trusted PC/session, not as a general default for arbitrary machines.
