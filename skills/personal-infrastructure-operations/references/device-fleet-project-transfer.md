# Device-fleet project transfer over SSH

Use when Semyon asks to move a small project or artifact between his own machines, especially PC ↔ laptop, and expects the agent to use the documented device fleet rather than asking for manual upload.

## Pattern

1. Read/consult the fleet inventory first for aliases, LAN IPs, Tailscale IPs, proxy caveats, and preferred access paths.
2. Probe source and destination with fast, read-only SSH:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=8 <host> 'hostname; pwd'
```

3. Search the source for likely project paths, pruning caches and dependencies. Prefer user project roots such as `~/code`, `~/Downloads`, and documented work directories.
4. Inspect the source directory before copying:
   - `git status --short` if it is a repo
   - `du -sh .`
   - small file manifest (`find . -maxdepth 2 -type f ...`)
5. Probe the destination path to avoid overwriting unexpected work. If the path exists, inspect status/size first before replacing.
6. For small projects, stream a tarball directly from source to destination through the control node. This avoids leaving temporary archives and works even when source and destination cannot reach each other directly:

```bash
set -o pipefail
ssh -o BatchMode=yes -o ConnectTimeout=8 pc \
  'cd /home/semyon/code/personal && tar -czf - go-expenses' \
| ssh -o BatchMode=yes -o ConnectTimeout=8 semyon@100.127.128.15 \
  'mkdir -p /home/semyon/code/personal && tar -C /home/semyon/code/personal -xzf -'
```

7. Verify on the destination with hostname, final path, size, and manifest. If relevant, run the narrow project check (`go test ./...`, `npm test`, etc.) but report plainly when the runtime is not installed/on PATH.

## Image/rendered-asset transfer and viewing

When Semyon asks for rendered project assets (SVGs/PNGs/PDFs) on another device:

1. Interpret the requested file types literally and narrowly. If he corrects “SVG/PDF” to “PNG”, switch to PNGs only; do not keep sending PDFs or unrelated formats.
2. Prefer human-useful rendered assets over repo noise. Include likely project outputs under `screenshots/`, `diagrams/rendered/`, and app `public/` assets; prune dependencies/build/cache plus coverage-report icons/sort sprites unless explicitly requested.
3. Preserve the source directory layout during transfer so filenames with similar names remain distinguishable:

```bash
rsync -av --files-from=/tmp/manifest.txt "$SRC/" "host:$DEST/"
```

4. For remote desktop viewing over SSH, probe native viewers first (`loupe`, `gwenview`, `inkscape`, `imv`, `swayimg`, etc.) and launch with the active desktop environment (`XDG_RUNTIME_DIR`, `WAYLAND_DISPLAY`, `DBUS_SESSION_BUS_ADDRESS`).
5. Do not assume a process listing proves the viewer worked for Semyon. If the native viewer appears but the user says it did not work, make a simple local `gallery.html` in the destination directory and open it in Helium as the browser fallback.
6. For Helium on Semyon's Cachy/Hyprland devices, the executable may be under `/opt/helium-browser-bin/helium`; use the absolute path if `systemd-run --user helium ...` cannot resolve it.

## Fleet-specific pitfall

The `laptop` SSH alias may route via NAS/LAN and fail with `No route to host` even when the laptop is reachable over Tailscale. If LAN/NAS proxy fails, try the documented raw Tailscale target, currently `semyon@100.127.128.15`, before asking Semyon to move files manually.

Do not persist negative conclusions like “laptop SSH is broken”; record the working access path and evidence date in the fleet inventory when appropriate.
