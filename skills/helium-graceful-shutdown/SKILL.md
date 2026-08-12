---
name: helium-graceful-shutdown
description: "Use when Helium loses sessions after a PC reboot."
version: 1.0.0
created_by: agent

metadata:
  harness: [hermes]
---

# Helium graceful shutdown on Semyon's PC

Use when Helium on `pc` (CachyOS/Hyprland) loses Discord or other web-app sessions after a full system reboot.

## Diagnose first

1. Confirm the running **parent** process uses the intended secure store:
   ```bash
   ssh pc 'ps -u "$USER" -o pid=,args= | grep "/opt/helium-browser-bin/helium " | grep -v -- "--type="'
   ```
   Expected flag: `--password-store=gnome-libsecret`.
2. Confirm `org.freedesktop.secrets` is owned by GNOME Keyring:
   ```bash
   ssh pc 'busctl --user --no-pager list | grep org.freedesktop.secrets'
   ```
3. Inspect `~/.config/net.imput.helium/Default/Preferences` read-only. If `profile.exit_type` repeatedly reads `Crashed`, investigate graceful shutdown rather than replacing the password-store backend.
4. Check for a clear-on-exit policy before changing lifecycle behavior. Do not read or print browser tokens/cookie values.

## Durable fix

The PC dotfiles own these host-specific files:

- `pc/.local/bin/helium-graceful-exit`
- `pc/.config/systemd/user/helium-graceful-shutdown.service`

The helper sends `SIGTERM` only to Helium’s non-`--type` parent process, waits up to 12 seconds for Chromium to commit its profile data, and only then sends `SIGKILL` if needed. The systemd user unit is `PartOf=` and `After=` `graphical-session.target`, so its `ExecStop` runs before the graphical session is stopped during a reboot.

Deploy/enable from the PC:

```bash
cd ~/dotfiles
stow -R pc
chmod 0755 ~/.local/bin/helium-graceful-exit
systemctl --user daemon-reload
systemctl --user enable --now helium-graceful-shutdown.service
systemctl --user is-active helium-graceful-shutdown.service
```

## Verify

- Static checks:
  ```bash
  bash -n ~/.local/bin/helium-graceful-exit
  systemctl --user show helium-graceful-shutdown.service -p PartOf -p After -p ExecStop -p ActiveState
  ```
- Have the user reboot normally, open Discord in Helium, and verify their session persists.
- If it still fails, collect non-secret journal and profile-exit evidence. The password-store shim should be reconsidered only if `gnome-keyring`/`org.freedesktop.secrets` fails at the same time.

## Pitfalls

- Do not use `--password-store=basic` while `gnome-keyring` is healthy; it weakens secret storage and does not address crash-like browser exits.
- Do not target all Chromium child processes: signal only `/opt/helium-browser-bin/helium` without a `--type=` argument, otherwise the parent may lose the opportunity to flush storage.
- Keep the service PC-specific; do not deploy it through the shared `home` Stow package.
