# Common Flatpak paths for a Windows-to-Linux handoff

Verify an app's layout on the target before writing. The following are useful starting points for the listed Flatpak IDs:

| App | Flatpak ID | Typical portable target |
|---|---|---|
| Prism Launcher | `org.prismlauncher.PrismLauncher` | `~/.var/app/org.prismlauncher.PrismLauncher/data/PrismLauncher/` |
| Steam | `com.valvesoftware.Steam` | `~/.var/app/com.valvesoftware.Steam/.local/share/Steam/userdata/` |
| Obsidian | `md.obsidian.Obsidian` | `~/.var/app/md.obsidian.Obsidian/config/obsidian/` |
| Brave | `com.brave.Browser` | `~/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser/` |

Migration rules:

- Copy only after the target app is installed; launching once may initialise its directory.
- Keep the source in `~/Migration-Archive/` and use `rsync -rltni --safe-links` to verify the mapping.
- For Brave/Chromium, expect Windows-encrypted passwords/cookies to require reauthentication.
- For Steam, restore userdata before login only when the owner accepts that Steam Cloud may ask them to choose between local and cloud saves.
- For Prism, do not import Windows Java binaries as the Linux runtime; copy instances and portable cosmetic/config assets instead.
