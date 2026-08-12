# Electron/AppImage CLI launch repair on Arch-style desktops

Use when a desktop Electron app installed from an AppImage/AUR package fails from the CLI or launcher with `Exec format error`, `cannot execute binary file`, or a wrapper points at a suspicious system binary.

## Diagnostic sequence

1. Identify all launch surfaces:
   - shell wrappers in `~/.local/bin`, `/usr/bin`, and package-provided aliases
   - desktop entries in `~/.local/share/applications` and `/usr/share/applications`
   - extracted AppImage payload under `/opt/<pkg>` or a user-local equivalent
2. Check binary identity before assuming architecture mismatch:
   - `file -L <wrapper-or-binary>`
   - `readelf -h <binary>` when `file` claims executable
   - `xxd -g1 -l 256 <binary>` when `file` says `data`
   - `pacman -Qo <path>` and `pacman -Qkk <package>` for ownership/integrity on Arch/CachyOS
3. If the installed payload is corrupted but the AUR cache/PKGBUILD is available, rebuild or at least fetch/extract the verified source:
   - `cd ~/.cache/paru/clone/<pkg>`
   - `makepkg -o --noconfirm`
   - confirm source checksum passes and extracted payload contains a real ELF binary
4. If sudo is unavailable, install a temporary/permanent user-local repair instead of stopping:
   - copy extracted `squashfs-root` to `~/.local/opt/<pkg>`
   - write wrappers in `~/.local/bin` that set `APPDIR`, payload `PATH`, `XDG_DATA_DIRS`, and `GSETTINGS_SCHEMA_DIR`
   - preserve existing app-specific flags such as `--no-sandbox`, Wayland ozone flags, and password-store flags
   - update the user desktop entry to point at the user-local wrapper

## Wrapper pattern

```bash
#!/usr/bin/env bash
set -euo pipefail
appdir="$HOME/.local/opt/<app>"
export APPDIR="$appdir"
export PATH="$appdir:$appdir/usr/bin:$appdir/usr/sbin:$PATH"
export XDG_DATA_DIRS="$appdir/usr/share${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
export GSETTINGS_SCHEMA_DIR="$appdir/usr/share/glib-2.0/schemas${GSETTINGS_SCHEMA_DIR:+:$GSETTINGS_SCHEMA_DIR}"
exec "$appdir/<binary>" --no-sandbox "$@"
```

Use a quoted heredoc (`<<'EOF'`) when writing the wrapper remotely; do not double-escape quotes inside it or the generated script will contain literal backslashes.

## GUI verification over SSH

Do not rely on `--version` for Electron apps; many launch the GUI and hang instead of printing a version. Verify with the active graphical session:

```bash
env \
  XDG_RUNTIME_DIR=/run/user/1000 \
  DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
  DISPLAY=:1 \
  WAYLAND_DISPLAY=wayland-1 \
  XDG_SESSION_TYPE=wayland \
  XDG_CURRENT_DESKTOP=Hyprland \
  nohup ~/.local/bin/<app> > /tmp/<app>.log 2>&1 &
```

Then check process state, app logs, desktop/window manager client list if available, and any local backend health endpoint the app should expose. For server-backed desktop apps, a successful `curl http://127.0.0.1:<port>/` is stronger evidence than a process existing.

## Pitfalls

- `Exec format error` can mean a zeroed/corrupted file, not just wrong CPU architecture.
- `pacman -Q` only proves package metadata exists; `pacman -Qkk` proves installed files still match.
- A wrapper may be correct while the payload it execs is corrupt.
- Remote SSH shells may have a different `PATH` from the user’s interactive terminal; check both `ssh host 'command -v app'` and `ssh host 'zsh -ic "command -v app"'` when launch behavior differs.
- Killing test Electron processes may leave short-lived defunct children; focus on whether a usable main process/backend remains.
