# VocaLinux workstation install/recovery

Use when Semyon asks to install, update, or repair VocaLinux on his Linux workstation.

## Source of truth

- Upstream repo: `https://github.com/jatinkrmalik/vocalinux`
- Website: `https://vocalinux.com/`
- Latest release can be checked through GitHub releases. Example known-good release from this session: `v0.13.0-beta` / package version `0.13.0b0`.

## Install/update pattern on PC

Run on `pc` as Semyon, not root. The upstream installer will use sudo for system packages when needed; use a PTY if it needs the password.

```bash
curl -fsSL https://raw.githubusercontent.com/jatinkrmalik/vocalinux/main/install.sh -o /tmp/vl.sh
bash /tmp/vl.sh --auto --tag=<latest-release-tag>
```

For a fully current install, resolve `<latest-release-tag>` from GitHub rather than reusing an old local version. The installer supports `--auto` and `--tag=TAG`.

## Verification

```bash
ls -l ~/.local/bin/vocalinux ~/.local/bin/vocalinux-gui ~/.local/bin/activate-vocalinux.sh
~/.local/share/vocalinux/venv/bin/python - <<'PY'
import importlib.metadata as m
print('vocalinux', m.version('vocalinux'))
PY
for f in ~/.local/share/applications/vocalinux.desktop ~/.config/autostart/vocalinux.desktop; do
  [ -f "$f" ] && echo "-- $f" && grep -E '^(Name|Exec|Icon|Categories)=' "$f"
done
```

Do not rely on `vocalinux --version`; at least in v0.13.0b0 it prints argparse help/error rather than a version. Use Python package metadata instead.

## Starting in the live Hyprland session

To actually start the tray app on Semyon's desktop from SSH:

```bash
export XDG_RUNTIME_DIR=/run/user/1000
export HYPRLAND_INSTANCE_SIGNATURE=$(ls -1 /run/user/1000/hypr | head -n1)
hyprctl dispatch exec 'env GI_TYPELIB_PATH= /home/semyon/.local/bin/vocalinux --start-minimized'
sleep 3
pgrep -af '[v]ocalinux' || true
```

## Vicinae/app-menu refresh

After install/update, refresh launcher entries:

```bash
update-desktop-database ~/.local/share/applications 2>/dev/null || true
systemctl --user restart vicinae.service
sleep 2
vicinae ping
```

Verify the desktop entry points at the wrapper:

```text
~/.local/share/applications/vocalinux.desktop
Exec=env GI_TYPELIB_PATH= /home/semyon/.local/bin/vocalinux-gui
```

## Pitfalls

- The installer may warn that the SSH session type is `tty`; this is expected when installing remotely. Continue in auto mode if dependencies are present/installed.
- On Arch/CachyOS, the installer may invoke `pacman` via sudo for tools such as `xdotool`/`wtype`; handle the prompt through a PTY, not `sudo -S`.
- `vocalinux --version` is not a reliable check; use package metadata.
- Installing files is not enough for Semyon's immediate workflow: start the tray process in the live Hyprland session and refresh Vicinae if he expects it to appear in the launcher.
