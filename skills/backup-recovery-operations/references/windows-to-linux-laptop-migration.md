# Windows-to-Linux Laptop Migration via Live Boot

Use this when replacing Windows with Linux while retaining a complete rollback image and an immediately usable user-data migration copy.

## Two independent recovery products

Create both before changing partitions:

1. **Whole-disk image**: rollback insurance. A raw image contains Windows, EFI/recovery partitions, local user data, and installed software state, but is inconvenient for routine file recovery.
2. **Normal migration tree**: copy selected user files into ordinary directories so they can be restored into the Linux account without extracting an image.

Do not claim the normal tree includes cloud-only OneDrive/Files-On-Demand content just because an image exists.

## Live-boot preflight

1. Inventory disks using model, transport, size, partition labels, and mountpoints. Explicitly name both the internal target disk and the external backup disk.
2. Mount the Windows data partition **read-only** for discovery/copying. Unmount it before invoking an installer.
3. Confirm the external destination has capacity for the raw image *plus* the migration tree. `lsblk` commonly displays binary GiB while raw-image byte counts are decimal; calculate using `blockdev --getsize64`.
4. If remotely operated, require LAN SSH access and verify login/key authentication before destructive install work. Prefer an ephemeral SSH key over sharing a live-session password in a group chat. Leave passwords out of logs/chat.

## Migration scope

Copy standard directories individually: Desktop, Documents, Downloads, Pictures, Music, Videos, Saved Games, and browser favourites/bookmarks where applicable.

Then explicitly preserve game/application state into an archive rather than forcing Windows configuration into Linux locations:

- Minecraft `.minecraft` and Prism Launcher data
- Steam `userdata` and selected launcher/game save directories
- selected browser profiles (archive only; Windows DPAPI-encrypted saved passwords/cookies are not portable)
- Obsidian app configuration and vault location metadata
- inventories of installed-program directory names and a file manifest

### OneDrive and Obsidian caveat

Windows OneDrive Files-On-Demand roots may appear from Linux NTFS mounts as unsupported reparse links. Their cloud content is not independently captured by an ordinary Linux copy. Inspect Obsidian's configuration for vault paths: if they point to OneDrive, preserve the configuration, retain the disk image, and restore/download the vault after Linux installation by signing into the relevant personal/school OneDrive account. For an offline independent copy, boot Windows and copy/download the vault normally before erasing it.

## Image and verification

For a destination that has sufficient spare capacity, a raw image is viable from a generic Linux live boot:

```bash
dd if=/dev/<internal-disk> of=/path/on/external/windows-full-disk.img \
  bs=16M iflag=fullblock status=progress conv=fsync
sha256sum /path/on/external/windows-full-disk.img \
  > /path/on/external/windows-full-disk.img.sha256
sync
```

Never construct the device path from memory; take it from the preflight inventory. A raw image is exact but may be near full-disk size, especially when BitLocker/device encryption prevents useful compression. A completed SHA-256 generation proves the produced image could be fully read; it records a future integrity reference, but is not an independent comparison against a source hash.

## Restore approach

After a clean Linux install, restore ordinary files into the new home directories. Put game and Windows-app data under `~/Migration-Archive/` first, dry-run compare with `rsync -rltni`, then install Linux-native applications and migrate only their relevant data to documented Linux paths. This prevents Windows-only cache/config files from polluting a new desktop.

Keep the external image and migration tree until the user has tested required browser school services, cloud access, game saves, hardware, and remote support.