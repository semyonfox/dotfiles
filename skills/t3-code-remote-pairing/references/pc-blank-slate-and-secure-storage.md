# PC T3 Code blank slate and secure-storage fallback

Session-derived workflow for Semyon's CachyOS/Arch `pc` when he wants the workstation T3 Code reset without touching the server backend.

## Scope rule

When Semyon says PC-only / keep server as-is / uninterrupted, do not stop `t3-code-headless.service` on `server`. Operate through SSH to `pc` only.

## True blank slate on PC

Move state aside rather than deleting it:

```bash
ssh pc 'set -euo pipefail
stamp=$(date +%Y%m%d-%H%M%S)
mkdir -p "$HOME/t3-restore-backups"
killall -9 t3code 2>/dev/null || true
[ -e "$HOME/.t3" ] && mv "$HOME/.t3" "$HOME/t3-restore-backups/.t3.before-blank-slate-$stamp"
[ -e "$HOME/.config/t3code" ] && mv "$HOME/.config/t3code" "$HOME/t3-restore-backups/.config-t3code.before-blank-slate-$stamp"
export XDG_RUNTIME_DIR=/run/user/1000
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
export XDG_CURRENT_DESKTOP=Hyprland
export HYPRLAND_INSTANCE_SIGNATURE=$(ls -1 /run/user/1000/hypr | /usr/bin/head -n1)
hyprctl dispatch exec "$HOME/.local/bin/t3code-nightly" >/tmp/t3code-blank-slate.log 2>&1 || true
'
```

Verify the new DB is really empty:

```bash
ssh pc 'python3 - <<"PY"
import sqlite3
from pathlib import Path
con=sqlite3.connect(Path.home()/".t3/userdata/state.sqlite")
cur=con.cursor()
print(cur.execute("PRAGMA integrity_check").fetchone()[0])
for t in ["projection_projects","projection_threads","projection_thread_messages","projection_thread_sessions"]:
    print(t, cur.execute("select count(*) from "+t).fetchone()[0])
PY'
```

Expected blank slate counts are all `0`.

## Secure storage unavailable during pairing

If the desktop shows:

```text
Could not register connection: ConnectionTransientError: Could not save the local connection catalog: Desktop secure storage is unavailable in this system context.
```

first inspect what password store already works on that machine or a comparable one. On Semyon's PC, Chromium/Helium and GNOME keyring were already using:

```text
--password-store=gnome-libsecret
```

and `org.freedesktop.secrets` was owned by `gnome-keyring-daemon`. In that case prefer cloning the working store (`gnome-libsecret`) over falling back to `basic`. Use `basic` only when no real secret service is present/healthy.

Probe:

```bash
ssh pc 'set -euo pipefail
ps -u "$USER" -o pid=,args= | grep -Ei "password-store|chromium|helium|brave|chrome" | grep -v grep || true
busctl --user --no-pager list 2>/dev/null | grep -Ei "org.freedesktop.secrets|gnome-keyring|kwallet" || true
pacman -Q gnome-keyring libsecret kwallet kwallet-pam 2>/dev/null || true
'
```

Avoid editing `/usr/bin/t3code-nightly` with `sudo -S`; Hermes blocks piped sudo-password use. Prefer a user-level wrapper and `.desktop` override. If `~/.local/bin/t3code-nightly` is a symlink to `/usr/bin/t3code-nightly`, remove the symlink first and replace it with a real wrapper:

```bash
ssh pc 'set -euo pipefail
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"
[ -L "$HOME/.local/bin/t3code-nightly" ] && rm "$HOME/.local/bin/t3code-nightly"
cat > "$HOME/.local/bin/t3code-nightly" <<"EOF"
#!/usr/bin/env bash
exec /usr/bin/t3code-nightly --password-store=gnome-libsecret "$@"
EOF
chmod +x "$HOME/.local/bin/t3code-nightly"
cat > "$HOME/.local/share/applications/t3code-nightly.desktop" <<"EOF"
[Desktop Entry]
Name=T3 Code Nightly
Comment=T3 Code nightly desktop build
Exec=/home/semyon/.local/bin/t3code-nightly %U
Terminal=false
Type=Application
Icon=t3code-nightly
StartupWMClass=t3code
Categories=Development;
EOF
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
systemctl --user restart vicinae.service 2>/dev/null || true
killall -9 t3code 2>/dev/null || true
export XDG_RUNTIME_DIR=/run/user/1000
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
export XDG_CURRENT_DESKTOP=Hyprland
export HYPRLAND_INSTANCE_SIGNATURE=$(ls -1 /run/user/1000/hypr | /usr/bin/head -n1)
hyprctl dispatch exec "$HOME/.local/bin/t3code-nightly" >/tmp/t3code-user-wrapper.log 2>&1 || true
'
```

Verify the parent app process includes the selected password store flag and that catalog writes succeed:

```bash
ssh pc 'set -euo pipefail
ps -u "$USER" -o pid=,args= | grep -E "/opt/t3code-nightly-bin/t3code|apps/server/dist/bin.mjs" | grep -v grep
grep -i "connectionCatalogStore.set" "$HOME/.t3/userdata/logs/desktop.trace.ndjson" 2>/dev/null | tail -n 5 || true
'
```

## Data copy caveat

If copying server `.t3` to PC, compressed tar streaming is faster than raw rsync for the multi-GB SQLite DB over LAN. But if Semyon later says blank slate is acceptable, stop copying and do the blank-slate move instead.
