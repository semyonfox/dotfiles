# Hyprland + Vicinae: stale config versus active Lua

## Symptom

Vicinae (`vicinae-bin 0.24.0-1`) was installed and had a packaged user unit, but did not reliably start with the user's Hyprland session. A manual service start worked, which initially obscured the persistence issue.

## Evidence that mattered

- `vicinae.service` was inactive before manual intervention, with no crash loop.
- The service's user-manager environment already contained valid Hyprland variables (`WAYLAND_DISPLAY`, `HYPRLAND_INSTANCE_SIGNATURE`, `XDG_RUNTIME_DIR`, and DBus bus address).
- `~/.config/hypr/hyprland.conf` contained:
  ```conf
  exec-once = systemctl --user restart vicinae.service
  ```
  but it was not the effective startup definition.
- The live `Super+Space` binding appeared once in `hyprctl binds -j`, with `dispatcher: "__lua"`.
- `~/.config/hypr/hyprland.lua` had the active `hl.on("hyprland.start", ...)` command list, but lacked a Vicinae service action.

## Correct remediation

Preserve the existing session ordering and add the unit restart after environment import in the **Lua** startup list:

```lua
"dbus-update-activation-environment --systemd --all",
"systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
"systemctl --user restart vicinae.service", -- start launcher after Wayland env is imported
```

Keep the packaged unit's `graphical-session.target.wants/vicinae.service` link as a lifecycle backstop. The Lua hook is still important because it guarantees launch after the session variables have been imported.

## Validation used

1. Timestamped backup of `hyprland.lua`.
2. `luac -p` succeeded silently.
3. `systemctl --user restart vicinae.service` produced an active/running service with `NRestarts=0`.
4. `vicinae open` created a Hyprland layer with `namespace: vicinae`.
5. Exactly one live `Super+Space` binding remained.

## Do not infer

- A manual `systemctl --user start` is not an autostart test.
- The presence of similarly named `.conf` and `.lua` files is not inherently conflicting; runtime bindings determine which path is active.
- A non-fatal Vicinae news-state parse warning is not evidence of a Wayland startup failure.
