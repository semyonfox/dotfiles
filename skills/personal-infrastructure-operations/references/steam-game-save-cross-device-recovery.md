# Steam game save cross-device recovery

Use when Semyon asks to find a missing Steam game save across his device fleet and make the best save common everywhere.

## Workflow

1. **Inventory reachable devices first.** Consult SSH aliases/fleet knowledge, then probe with short BatchMode/ConnectTimeout SSH. Record which devices are unreachable rather than silently skipping them.
2. **Identify the Steam app precisely.** On reachable machines, parse `~/.local/share/Steam/steamapps/libraryfolders.vdf` and each `appmanifest_*.acf` to find candidate games by name and AppID. Do not rely only on memory or store search if manifests are available.
3. **Locate installs and save roots.** Check:
   - `~/.local/share/Steam/steamapps/common/<install dir>`
   - `~/.steam/steam/steamapps/common/<install dir>`
   - Steam userdata: `~/.local/share/Steam/userdata/*/<appid>/`, `~/.steam/steam/userdata/*/<appid>/`
   - Proton/compatdata: `~/.local/share/Steam/steamapps/compatdata/<appid>/`
   - Native Unity/Godot-style locations: `~/.local/share/<Game Name>/`, `~/.config/unity3d/`, `~/.config/<Game Name>/`
4. **Search narrowly and prune junk.** For broad roots, prune cache/shader/log/browser/node directories. Prefer files with save-like extensions (`.sav`, `.save`, `.dat`, `.json`, `.bin`, `.es3`, `.bytes`) and paths containing the AppID or game name.
5. **Choose the common save with evidence.** Usually pick the largest save, tie-breaking by newest mtime if sizes match. Compute hash and stat output before mutation.
6. **Back up before overwriting.** On every device with a save, create a timestamped backup directory beside the save directory before copying. Preserve metadata (`cp -a`, `touch -r`) when cloning one slot to others.
7. **Handle multiple local slots.** Some games keep `savegame.dat`, `savegame1.dat`, `savegame2.dat`, etc. If the user wants the best save as the common save, copy the selected source into all save slots on that device after backup, then verify identical hashes.
8. **Verify the Steam install exists too.** If a reachable device has saves but no appmanifest/install, report that it has a save but not an installed Steam game. If it has the game installed but no save, copy only after confirming the correct destination save path from the discovered game conventions.
9. **Report unreachable devices plainly.** Do not claim fleet-wide completion if a laptop/PC/phone is offline. Say exactly which devices were updated and what still needs to be online for the next pass.

## Upload Labs example

For Upload Labs (`appid 3606890`) on Linux, the native save root observed was:

```text
~/.local/share/Upload Labs/
```

Save slots observed:

```text
savegame.dat
savegame1.dat
savegame2.dat
savegame3.dat
savegame_2.2.9.dat
mod_user_profiles.json
mod_loader_cache.json
steam_autocloud.vdf
```

Steam Cloud metadata appeared under:

```text
~/.local/share/Steam/userdata/<accountid>/3606890/remotecache.vdf
```

When normalizing save slots, leave `steam_autocloud.vdf` and `remotecache.vdf` alone unless there is a specific cloud-sync repair request; copy only the selected game save files and verify with `sha256sum`/`stat`.
