# Windows-to-Linux migration from a live USB

## Purpose

Use this when replacing a Windows laptop with Linux while preserving a reversible Windows fallback and a convenient migration set. Treat these as separate artifacts:

- **Disk image:** full rollback of the old disk (EFI, recovery, OS, applications, user data).
- **Browseable migration tree:** ordinary files that can be restored directly into the new home directory.

## Safe sequence

1. Obtain explicit authorization for the device and scope. In a group chat, do not request or repeat passwords; prefer a temporary SSH key for a live session.
2. Boot the live environment, connect networking, and inspect with `lsblk`/`blkid`/`df` before mounting or copying. Identify source and target by model, transport, capacity, filesystem labels, and mountpoints — never only `/dev/sdX` order.
3. Mount the old Windows volume read-only for inventory. Check for redirected OneDrive/school folders: offline cloud placeholders and unsupported reparse points do not prove that cloud-only files are present locally.
4. Make a dedicated target root such as `Windows-to-Linux-migration-YYYY-MM-DD/`, with `files/`, `game-data/`, `app-data/`, `inventories/`, and `image/` subdirectories.
5. Copy normal user folders first, then app/game-specific data. Keep a file manifest and record total size. Expected optional sources include:
   - `Desktop`, `Documents`, `Downloads`, `Pictures`, `Music`, `Videos`, `Saved Games`, school/project folders, and browser favourites.
   - Minecraft `.minecraft` and Prism Launcher/other launcher data.
   - Steam `userdata`; download game installations again unless bandwidth makes preserving them worthwhile.
   - selected browser profiles, Epic/other launcher save/config data, note-app vault/config folders, and AI/tool configuration that the user explicitly wants retained.
   - a program-directory inventory. It is a reinstall checklist, not an application migration mechanism.
6. Only after the migration tree completes, image the entire old disk to a confirmed separate writable destination. Raw images need at least the full source-disk size free; BitLocker/encrypted disks may not compress usefully. Generate and retain a checksum or use the imaging tool's verification pass.
7. Verify representative files from the migration tree and verify the image before any partitioning. Leave the image and migration tree intact until the new OS passes real account, hardware, school-app, and game tests.

## Writable USB and remote-access pitfalls

- A normally flashed ISO partition is boot media, not a general-purpose file destination. A Ventoy USB can expose an additional writable data partition; confirm it separately with `lsblk` and `df`.
- A live OS can run a short-lived SSH daemon for LAN assistance. Restrict access to the local network, inspect first, and let the access vanish when the live session is rebooted. Do not leave a persistent remote-access configuration on the target without a separate explicit decision.
- Do not copy whole `AppData` by default merely because it is large. Inventory it, preserve clear configuration/save sources, and let caches and installed Windows programs be recreated. A full disk image already protects anything omitted from the browseable tree.
