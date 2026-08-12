# T3 Code workstation recovery and blank-slate operations

Use this reference when Semyon's T3 Code desktop/workstation state is missing, mismatched, corrupted, or needs a clean reset while the server/headless T3 instance must stay untouched.

## Durable lessons from the July 2026 recovery

- For Semyon's setup, keep the CLI on `npm t3@nightly` when the desktop package is `t3code-nightly-bin`; `npm t3@latest` can lag behind and cause channel/schema confusion.
- When Semyon says “no symlink shite,” copy real directories/files. Do not replace `~/.t3` or `~/.config/t3code` with symlinks to another device.
- For device-local recovery, stop only the target device's T3 desktop/server processes. Do not interrupt server/headless T3 unless explicitly doing a server-origin copy and the user accepts the brief stop.
- For secure-storage failures on Hyprland/headless-ish launches, add Chromium/Electron flag `--password-store=basic` to the desktop launch command.

## PC-only true blank slate

This preserves old state by moving it aside, then launches a fresh PC-local T3 instance. It does not touch the server.

```bash
ssh pc 'set -euo pipefail
stamp=$(date +%Y%m%d-%H%M%S)
mkdir -p "$HOME/t3-restore-backups"
killall -9 t3code 2>/dev/null || true
sleep 2
[ -e "$HOME/.t3" ] && mv "$HOME/.t3" "$HOME/t3-restore-backups/.t3.before-blank-slate-$stamp"
[ -e "$HOME/.config/t3code" ] && mv "$HOME/.config/t3code" "$HOME/t3-restore-backups/.config-t3code.before-blank-slate-$stamp"
export XDG_RUNTIME_DIR=/run/user/1000
export HYPRLAND_INSTANCE_SIGNATURE=$(ls -1 /run/user/1000/hypr | /usr/bin/head -n1)
hyprctl dispatch exec "/usr/bin/t3code-nightly --password-store=basic"
sleep 8
curl -fsS --max-time 8 http://127.0.0.1:3773/.well-known/t3/environment
'
```

Verify the DB is blank:

```bash
ssh pc 'python3 - <<"PY"
import sqlite3
from pathlib import Path
DB = Path.home()/".t3/userdata/state.sqlite"
con = sqlite3.connect(DB); cur = con.cursor()
print("integrity", cur.execute("PRAGMA integrity_check").fetchone()[0])
for t in ["projection_projects", "projection_threads", "projection_thread_messages", "projection_thread_sessions"]:
    print(t, cur.execute("select count(*) from "+t).fetchone()[0])
PY'
```

Expected blank counts are all `0`.

## Make the secure-storage fallback persistent in app launchers

Write a user-level desktop entry so launchers/Vicinae prefer the password-store flag over `/usr/share/applications`:

```bash
ssh pc 'cat > ~/.local/share/applications/t3code-nightly.desktop <<"EOF"
[Desktop Entry]
Name=T3 Code Nightly
Comment=T3 Code nightly desktop build
Exec=/usr/bin/t3code-nightly --password-store=basic %U
Terminal=false
Type=Application
Icon=t3code-nightly
StartupWMClass=t3code
Categories=Development;
EOF
update-desktop-database ~/.local/share/applications 2>/dev/null || true
systemctl --user restart vicinae.service 2>/dev/null || true'
```

## Copy server state to PC when explicitly requested

Only use this when the user wants server `.t3` state copied to PC. Prefer compressed tar streaming over raw rsync for large SQLite files; raw rsync over Wi-Fi can take a long time. Exclude generated logs/backups unless the user asks for forensics.

```bash
# on server
stamp=$(date +%Y%m%d-%H%M%S)
ssh pc "mkdir -p ~/t3-restore-backups; [ -e ~/.t3 ] && mv ~/.t3 ~/t3-restore-backups/.t3.before-server-copy-$stamp || true"
systemctl --user stop t3-code-headless.service
trap 'systemctl --user start t3-code-headless.service' EXIT
tar -C "$HOME" \
  --exclude='.t3/userdata/logs' \
  --exclude='.t3/userdata/backups' \
  -I 'zstd -1 -T0' -cf - .t3 \
  | ssh pc 'tar -I zstd -xpf - -C "$HOME"'
```

Then verify on PC:

```bash
ssh pc 'python3 - <<"PY"
import sqlite3
from pathlib import Path
DB = Path.home()/".t3/userdata/state.sqlite"
con = sqlite3.connect(DB); cur = con.cursor()
print("integrity", cur.execute("PRAGMA integrity_check").fetchone()[0])
print("threads total/nondeleted/deleted", cur.execute("select count(*), sum(deleted_at is null), sum(deleted_at is not null) from projection_threads").fetchone())
print("messages", cur.execute("select count(*) from projection_thread_messages").fetchone()[0])
for r in cur.execute("select title,updated_at from projection_threads where deleted_at is null order by updated_at desc limit 8"):
    print("active_thread", r)
PY'
```

## Pitfalls

- `pkill -f` patterns can match the remote shell command itself and kill the SSH session. Prefer `killall -9 t3code` on the PC for urgent cleanup, then verify with `ps -u "$USER" -o pid=,stat=,args=`.
- T3 logs and DB backups can be tens of GB. Excluding `.t3/userdata/logs` and `.t3/userdata/backups` keeps a task/config restore focused and much faster.
- If launching via Hyprland `hyprctl dispatch exec`, check the process list and the `.well-known/t3/environment` endpoint; dispatch success only means Hyprland accepted the command.
