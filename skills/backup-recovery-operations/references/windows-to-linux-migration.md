# Windows-to-Linux Laptop Migration

## Recovery model

Use two distinct artifacts before replacing Windows:

1. **Whole-disk image** — rollback artifact. It contains OS, EFI/recovery partitions, installed programs, user profile, and local files. It is for restoring the old disk, not convenient individual-file browsing.
2. **Normal migration tree** — accessible artifact. Copy user-facing folders and selected app/game data into an obvious directory on a separate writable partition or NAS. This is what gets restored into the new Linux home directory.

Never declare the migration protected until the image completed cleanly and has an adjacent SHA-256 record. A newly generated checksum proves the image was readable at the time it was made; retain it so future copies/restores can be checked with `sha256sum -c`.

## Live-USB workflow

- Identify disks by **model, transport, size, and removable flag**; never rely solely on `/dev/sdX` lettering.
- Mount the old Windows data partition read-only for extraction. Unmount it before launching the Linux installer.
- Keep the recovery USB attached but make the installer target explicit: internal disk only, never the removable backup disk.
- A raw `dd` image can be a practical fallback where the destination has enough room for the entire source disk. It copies every block and therefore needs capacity for the full device size, not merely apparent Windows usage. Purpose-built imaging tools can be more space-efficient.
- Do not write personal documents into the ISO/Ventoy boot partition. Use an explicitly writable data partition, a second disk, or the NAS.

## Windows data allow-list

Copy standard folders if present: `Desktop`, `Documents`, `Downloads`, `Pictures`, `Music`, `Videos`, `Saved Games`, and `Favorites`.

Preserve app-specific data separately when relevant:

- Minecraft Java: `%APPDATA%\\.minecraft`
- Prism Launcher: `%APPDATA%\\PrismLauncher`
- Steam: `Steam/userdata` plus any game-specific saves
- Browser profile archive/config (do not promise Windows-encrypted passwords will import on Linux)
- note-app configuration and vaults; determine vault paths before assuming notes live inside the app config directory
- selected launcher/game configuration, not full game installations unless an explicit offline/re-download constraint warrants it

Create a human-readable inventory of Program Files directories/app choices to make reinstallation easy. Do not copy `Program Files` as a migration mechanism.

## OneDrive caveat

Windows OneDrive Files On-Demand locations may appear to Linux NTFS tooling as unsupported reparse points. Treat them as cloud-rooted data, not proof that a normal local copy was made.

- Record the OneDrive vault/folder paths from app configuration.
- Keep the full disk image as fallback.
- After Linux installation, sign into the appropriate personal and school OneDrive accounts and retrieve/verify the required files.
- If an offline independent copy is required, boot Windows before wiping and copy/download the OneDrive folders through Windows while they are available locally.
