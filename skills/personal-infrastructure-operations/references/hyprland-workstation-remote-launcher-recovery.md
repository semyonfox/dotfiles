# Hyprland workstation remote launcher recovery

Use when Semyon urgently asks from chat to launch/focus a GUI app on his PC, or says a Hyprland shortcut such as `Win+Space` stopped doing anything.

## Fast path

1. SSH to the PC fleet alias, usually `pc`, and verify the host/session:

```bash
ssh pc 'hostname; id -u; loginctl list-sessions --no-legend'
```

2. Set Hyprland session env for remote commands:

```bash
export XDG_RUNTIME_DIR=/run/user/1000
export HYPRLAND_INSTANCE_SIGNATURE=$(ls -1 /run/user/1000/hypr | head -n1)
```

3. Wake displays if the request is happening through RustDesk/remote screen sharing:

```bash
hyprctl dispatch dpms on
```

4. For an already-running GUI app, focus it rather than relaunching:

```bash
hyprctl clients -j | jq -r '.[] | select((.class|test("obs|OBS";"i")) or (.title|test("obs|OBS";"i"))) | "addr=\(.address) class=\(.class) title=\(.title) workspace=\(.workspace.name) mapped=\(.mapped)"'
hyprctl dispatch focuswindow class:com.obsproject.Studio
```

5. If a keybinding does nothing, inspect the live bind and process/binary state:

```bash
hyprctl binds | grep -i -A2 -B2 'SPACE\|vicinae\|rofi\|wofi\|anyrun\|launcher' || true
pgrep -a 'vicinae|rofi|wofi|anyrun|walker|ulauncher|albert|fuzzel' || true
command -v vicinae rofi wofi fuzzel walker 2>/dev/null || true
```

6. Provide a visible fallback immediately if the primary launcher is broken:

```bash
hyprctl dispatch exec 'pkill -x rofi || /home/semyon/.local/share/bin/rofilaunch.sh d'
```

## Vicinae missing-binary recovery, proper Arch install, and app-entry refresh

If Hyprland binds `Super+Space` to a Vicinae command but the binary is missing, do not stop at “command not found.” First provide a visible fallback (usually rofi) so Semyon can keep working, then repair the install.

### Preferred durable fix on Arch/CachyOS

Follow the Vicinae docs for Arch: install the AUR package with the user's preferred helper. Use `vicinae-bin` for fast recovery unless Semyon explicitly wants a source build.

```bash
paru --skipreview --noconfirm -S --needed vicinae-bin
# docs show yay -S vicinae-bin; paru is fine on Semyon's PC when that is the installed AUR helper
```

If sudo is required over SSH, use a TTY/PTY flow so the prompt is handled normally; do not pipe passwords to `sudo -S`.

After installing, remove any temporary local wrapper from an emergency recovery and update Hyprland binds to the packaged binary:

```bash
rm -f ~/.local/bin/vicinae
rm -rf ~/.local/opt/vicinae-* ~/.local/opt/vicinae-deps
python - <<'PY'
from pathlib import Path
p = Path.home()/'.config/hypr/userprefs.conf'
s = p.read_text()
s = s.replace('/home/semyon/.local/bin/vicinae toggle', '/usr/bin/vicinae toggle')
p.write_text(s)
PY
systemctl --user enable --now vicinae.service
```

Then reload and verify:

```bash
export XDG_RUNTIME_DIR=/run/user/1000
export HYPRLAND_INSTANCE_SIGNATURE=$(ls -1 /run/user/1000/hypr | head -n1)
hyprctl reload
vicinae ping
vicinae toggle
vicinae state open && echo open
systemctl --user is-enabled vicinae.service
systemctl --user is-active vicinae.service
pacman -Q vicinae-bin
```

### Refresh Vicinae app entries after installing/reinstalling desktop apps

When a GUI app was reinstalled and Semyon says Vicinae entries are missing/stale, update the desktop database and restart Vicinae so it re-indexes `.desktop` launchers:

```bash
update-desktop-database ~/.local/share/applications 2>/dev/null || true
systemctl --user restart vicinae.service
sleep 2
vicinae ping
```

Inspect the relevant desktop files for stale `Exec=` paths and fix/symlink only after verifying the intended binary. Example pattern:

```bash
for f in ~/.local/share/applications/*.desktop /usr/share/applications/*.desktop; do
  grep -qiE 't3|vocalinux|vicinae' "$f" 2>/dev/null && { echo --"$f"; grep -E '^(Name|Exec|Icon|Categories)=' "$f"; }
done
```

If a launcher points to a historical user-local path but the packaged binary is now under `/usr/bin`, either update the `.desktop` file or add a minimal symlink such as `~/.local/bin/<app> -> /usr/bin/<app>`; then restart Vicinae again and verify `vicinae ping`.

To explain why it disappeared, inspect package history and local leftovers:

To explain why it disappeared, inspect package history and local leftovers:

```bash
zgrep -hi 'vicinae' /var/log/pacman.log* 2>/dev/null || true
pacman -Q vicinae vicinae-bin 2>/dev/null || true
find ~/.local -maxdepth 4 \( -iname '*vicinae*' -o -path '*/vicinae/*' \) 2>/dev/null | sed -n '1,80p'
```

If pacman has no historical install record but `~/.config/vicinae`, `~/.local/share/vicinae`, local desktop files, or a Hypr bind to `~/.local/bin/vicinae` remain, treat it as a prior manual/script/AppImage-style install whose binary was later removed while config and keybinds stayed behind.

### Emergency user-local workaround

Use this only when Semyon needs the launcher immediately and proper sudo/AUR install cannot be completed yet. Recover it user-locally from the GitHub release tarball:

```bash
ver=0.22.3
opt="$HOME/.local/opt/vicinae-$ver"
mkdir -p "$opt" "$HOME/.local/bin"
tmp=$(mktemp -d)
cd "$tmp"
curl -L --fail -o vicinae.tar.gz "https://github.com/vicinaehq/vicinae/releases/download/v$ver/vicinae-linux-x86_64-v$ver.tar.gz"
tar -xzf vicinae.tar.gz -C "$opt"
```

If system dependencies such as `libqt6keychain.so.1`, `libLayerShellQtInterface`, or `libqalculate` are missing and `sudo` is not available over non-interactive SSH, unpack repo packages into a local dependency directory and wrap the binary with `LD_LIBRARY_PATH`:

```bash
dep="$HOME/.local/opt/vicinae-deps"
mkdir -p "$dep"
pacman -Sp qtkeychain-qt6 layer-shell-qt libqalculate > /tmp/vicinae-dep-urls.txt
cd "$dep"
while read -r url; do
  f=${url##*/}
  [ -f "$f" ] || curl -L --fail -O "$url"
  tar --use-compress-program=unzstd -xf "$f"
done < /tmp/vicinae-dep-urls.txt

cat > "$HOME/.local/bin/vicinae" <<'EOF'
#!/usr/bin/env bash
export LD_LIBRARY_PATH="$HOME/.local/opt/vicinae-deps/usr/lib:${LD_LIBRARY_PATH:-}"
exec "$HOME/.local/opt/vicinae-0.22.3/bin/vicinae" "$@"
EOF
chmod +x "$HOME/.local/bin/vicinae"
```

Then start and verify using the same `vicinae ping`, `vicinae toggle`, and `vicinae state open` checks. Replace this workaround with the AUR install as soon as sudo is available.

## Pitfalls

- `hyprctl dispatch exec` only reports Hyprland accepted the dispatch; the launched program can still fail. Run the app once directly over SSH to expose missing shared libraries.
- Avoid `echo ===...` in Semyon's zsh remote shell; `===foo===` can be treated as a command if quoting goes sideways. Use `printf '%s\n' '===foo==='`.
- A process named `power-profiles-daemon` can match loose `pgrep rofi` because of the substring `rofi`; prefer `pgrep -x rofi` when checking exact launcher state.
- If `paru -S` needs sudo and SSH has no TTY/password prompt, fall back to user-local release tarballs or AppImages instead of blocking.