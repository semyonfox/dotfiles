# Steam cross-device save sync and Windows-library rescue

Use when Semyon asks to find a missing Steam save across his devices, especially when one PC dual-boots or has a Windows Steam library on an NTFS drive.

## Workflow

1. Identify the game AppID and install locations from Steam library manifests, not from memory:

```bash
python3 - <<'PY'
import os, glob, re
roots=[]
for base in [os.path.expanduser('~/.local/share/Steam'), os.path.expanduser('~/.steam/steam')]:
    lf=os.path.join(base,'steamapps','libraryfolders.vdf')
    if os.path.exists(lf):
        roots.append(os.path.join(base,'steamapps'))
        txt=open(lf,errors='ignore').read()
        for p in re.findall(r'"path"\s+"([^"]+)"', txt):
            roots.append(os.path.join(p.replace('\\\\','/'),'steamapps'))
for root in dict.fromkeys(roots):
    for mf in glob.glob(os.path.join(root,'appmanifest_*.acf')):
        txt=open(mf,errors='ignore').read()
        name=re.search(r'"name"\s+"([^"]+)"', txt)
        appid=re.search(r'"appid"\s+"([^"]+)"', txt)
        inst=re.search(r'"installdir"\s+"([^"]+)"', txt)
        if name and ('upload' in name.group(1).lower() or 'idle' in name.group(1).lower()):
            print(mf, appid.group(1) if appid else '?', name.group(1), inst.group(1) if inst else '')
PY
```

2. Probe every reachable device via the fleet pattern. For each device, check Steam dirs and known save roots. Search local Linux roots plus Steam Cloud metadata:
   - `~/.local/share/Steam/userdata/*/<appid>/remotecache.vdf`
   - `~/.steam/steam/userdata/*/<appid>/remotecache.vdf`
   - `~/.local/share/Steam/steamapps/compatdata/<appid>/`
   - `~/.local/share/<Game Name>/`
   - `~/.config/unity3d/` for Unity games

3. For a Windows Steam library on the same Linux PC, do **not** trust a stale Steam manifest path alone. Verify the NTFS partition is actually mounted:

```bash
lsblk -f -o NAME,FSTYPE,LABEL,UUID,FSAVAIL,FSUSE%,MOUNTPOINTS
findmnt -rn -o TARGET,SOURCE,FSTYPE,OPTIONS | grep -Ei 'ntfs|windows|games|/mnt'
stat /mnt/windows-games
```

If `/mnt/windows-games` exists but is empty, the 1TB Windows partition is not mounted. Remote `udisksctl mount` may hang waiting for a GUI polkit prompt; `sudo mount` may require a password. Report this precisely and ask Semyon to mount/approve it locally, then rerun the sync.

4. Search Windows save locations once mounted. Common Godot/Steam locations include:
   - `<Windows mount>/Users/<user>/AppData/Roaming/<Game Name>/savegame*.dat`
   - `<Windows mount>/Users/<user>/AppData/Local/<Game Name>/savegame*.dat`
   - Steam userdata / AutoCloud paths under the mounted Steam library

5. Pick the best save by deterministic evidence: largest non-empty `savegame*.dat`, tie-break by newest mtime. Print size, mtime, path, and SHA256.

6. Before overwriting, back up each save directory in-place:

```bash
.backup-common-save-YYYYMMDD-HHMMSS/
```

Copy existing `savegame*.dat` plus small metadata files such as `steam_autocloud.vdf`, `mod_user_profiles.json`, and `mod_loader_cache.json` when present.

7. Copy the chosen source save across all existing save slots in every found save dir. For Upload Labs/Godot, also ensure the common slots exist: `savegame.dat`, `savegame1.dat`, `savegame2.dat`, `savegame3.dat`. Preserve source mtime where possible.

8. Verify with hashes after mutation:

```bash
stat -c '%s %y %n' savegame*.dat
sha256sum savegame*.dat
```

## Pitfalls

- Steam library manifests can list a Windows library path even when the NTFS partition is currently unmounted; an empty `/mnt/windows-games` means searches will falsely miss the Windows save.
- Do not overwrite based on “newest” alone; Semyon explicitly wanted the biggest save because a large save was missing.
- Do not treat Steam process presence as game presence. Check the game process separately before touching live save files.
- Keep the install dir separate from the save dir: `steamapps/common/<Game>` is not a save root even when it matches the game name.
