# Rendered artifact transfer and desktop opening

Use when Semyon asks to move rendered images/diagrams/screenshots between his machines and open them visually.

## Scope discipline

- Preserve conversational scope. If the user says “all SVGs/PDFs” after discussing “rendered SVGs/PNGs”, search the rendered artifact directories first (`diagrams/rendered/`, `screenshots/`, `artifacts/`, etc.), not the whole repo.
- Avoid surprising repo-wide matches such as root `report.pdf`, test fixtures like `scripts/e2e/fixtures/sample-paper.pdf`, dependency icons, or generated build assets unless explicitly requested.
- When a repo-wide sweep is genuinely requested, label odd inclusions before or while sending so the user is not left guessing why they appeared.

## Cross-device workflow

1. Consult/probe the fleet path. For Semyon's laptop, the `laptop` SSH alias may fail via LAN/NAS proxy; use the documented Tailscale fallback `semyon@100.127.128.15` when needed.
2. Copy with rsync preserving relative paths into a timestamped destination under `~/Downloads/` or `~/Pictures/`:

```bash
ROOT=/path/to/project
DEST="/home/semyon/Downloads/<project>-artifacts-$(date +%Y%m%d-%H%M%S)"
find "$ROOT/diagrams/rendered" "$ROOT/screenshots" -type f \( -iname '*.svg' -o -iname '*.png' -o -iname '*.pdf' \) -printf '%P\n' > /tmp/artifacts.txt
ssh semyon@100.127.128.15 "mkdir -p '$DEST'"
rsync -av --relative --files-from=/tmp/artifacts.txt "$ROOT/" "semyon@100.127.128.15:$DEST/"
```

Adapt the manifest if using multiple roots; verify the final count and paths on the destination.

## Opening SVGs natively on Hyprland/Wayland

1. Discover native viewers first: `gwenview`, `loupe`, `inkscape`, `rsvg-view-3`, `imv`, `swayimg`, `eog`, etc. Use browsers only as fallback; if Semyon asks for a browser fallback, prefer Helium when installed.
2. Export the user session environment before launching GUI apps over SSH:

```bash
export XDG_RUNTIME_DIR=/run/user/1000
export WAYLAND_DISPLAY=wayland-1
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
export DISPLAY=:0
```

3. On Semyon's laptop, `gwenview` is a good native SVG viewer when present. Launch through `uwsm app --` if available:

```bash
find "$DEST" -type f -iname '*.svg' | sort > /tmp/svg-list
nohup uwsm app -- gwenview $(sed "s/.*/'&'/" /tmp/svg-list | tr '\n' ' ') >/tmp/artifact-gwenview.log 2>&1 &
```

4. Verify with `ps -u semyon -o pid,comm,args | grep -E '(gwenview|loupe|helium)'` and report the destination path plus app used.
