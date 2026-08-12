# Windows SSD NTFS mount, migration, and VM planning

Use when Semyon wants to inspect, force-mount, shrink/move, or repurpose a Windows SSD from his Linux PC, especially when keeping Windows for anti-cheat gaming while moving Linux or creating a Windows VM for GUI/document automation.

## Known PC layout pattern from session

Example observed on `pc` / `semyon-pc-cachy`:

- Linux on 512GB SK hynix NVMe: EFI + LUKS + Btrfs, Limine boot.
- Windows/Fortnite on 1TB WD_BLACK SN850X: EFI + MSR + main NTFS + recovery.
- Windows boot entry and Linux Limine entry coexist in UEFI.
- Windows NTFS may be configured in `/etc/fstab` and can fail to mount due to dirty-bit state.

Do not assume exact device names are stable. Always rediscover with:

```bash
lsblk -o NAME,PATH,SIZE,TYPE,FSTYPE,LABEL,UUID,MOUNTPOINTS,MODEL,SERIAL
efibootmgr -v
findmnt -t ntfs,ntfs3,exfat,vfat || true
```

Use `/dev/disk/by-id/` or UUIDs for durable operations; avoid relying on `/dev/nvme1n1` across reboots.

## NTFS dirty-bit workflow

If mount fails with messages like:

```text
ntfs3(...): It is recommended to use chkdsk.
ntfs3(...): volume is dirty and "force" flag is not set!
mount: wrong fs type, bad option, bad superblock...
```

Preferred durable fix:

1. Boot Windows bare-metal.
2. Disable hibernation/Fast Startup:
   ```powershell
   powercfg /h off
   ```
3. Run `chkdsk C: /f` from an admin shell; reboot if requested.
4. Full shutdown:
   ```cmd
   shutdown /s /t 0
   ```
5. Boot Linux and mount normally.

If Semyon explicitly approves forced mounting despite the dirty bit, treat it as a scoped inspection/migration action:

- Back up `/etc/fstab` first.
- Prefer a generic mount name such as `/mnt/windows-drive` rather than purpose-specific names like `/mnt/windows-games`.
- Remove automount behaviour while doing inspection/migration unless there is a reason to keep it.
- Use `force` intentionally, and say plainly that Windows still needs `chkdsk` later.

Example fstab replacement after explicit approval:

```fstab
UUID=<windows-main-ntfs-uuid> /mnt/windows-drive ntfs3 uid=1000,gid=1000,windows_names,noatime,nofail,force 0 0
```

Commands pattern:

```bash
stamp=$(date +%Y%m%d-%H%M%S)
sudo cp -a /etc/fstab "/etc/fstab.backup-windows-drive-${stamp}"
sudo mkdir -p /mnt/windows-drive
sudo systemctl stop 'mnt-windows\x2dgames.automount' 'mnt-windows\x2dgames.mount' 2>/dev/null || true
# edit fstab carefully, then:
sudo systemctl daemon-reload
sudo mount /mnt/windows-drive
findmnt /mnt/windows-drive -o TARGET,SOURCE,FSTYPE,OPTIONS
```

Never force-mount dirty NTFS read/write silently. If only rescuing files, prefer `ro,force`.

## Space audit pattern

After mounting, gather broad totals first:

```bash
df -hT /mnt/windows-drive
find /mnt/windows-drive -xdev -type f -size +1G -printf '%s\t%p\n' 2>/dev/null | sort -nr | head -50
```

Use timeout-bounded `du` calls because Windows trees (`Program Files`, `Users`, `WindowsApps`, profile symlink/junction forests) can be slow or loop-prone:

```bash
for p in /mnt/windows-drive/* /mnt/windows-drive/.[!.]*; do
  [ -e "$p" ] || continue
  timeout 25 du -sh "$p" 2>/dev/null || echo "TIMEOUT/ERR $p"
done

timeout 120 du -hxd1 "/mnt/windows-drive/Users/<user>/AppData" 2>/dev/null | sort -h | tail -50
timeout 120 du -hxd1 "/mnt/windows-drive/Program Files" 2>/dev/null | sort -h | tail -50
timeout 120 du -hxd1 "/mnt/windows-drive/ProgramData" 2>/dev/null | sort -h | tail -50
```

Skip or handle carefully:

- `System Volume Information`
- Windows profile junctions such as `Application Data`, `Local Settings`, `My Documents`, `NetHood`, `PrintHood`, `Recent`, `SendTo`, `Start Menu`, `Templates`
- `WindowsApps` permissions quirks

## Migration-sizing heuristics

For moving Windows from a 1TB disk to a nominal 500GB SSD:

- Nominal 500GB SSD is around 465GiB usable.
- Aim for Windows used space under ~350GiB.
- Under ~400GiB is workable.
- 430GiB+ is cramped/risky.
- 500GiB+ will not fit.

Classify space as:

Keep on Windows for anti-cheat/gaming:

- Fortnite / Epic launcher and anti-cheat components
- Windows Gaming Services / WindowsApps pieces needed by games
- GPU/chipset/Razer/Armoury utilities if still used

Good move-to-Linux-or-NAS candidates:

- `Downloads` large `.mov`, `.zip`, `.iso`
- OBS recordings / rendered video exports
- old editing projects and sound libraries
- VirtualBox snapshots/VMs not used on Windows
- media files and old installers

Reinstall/clean from Windows rather than manually deleting from Linux when possible:

- Unreal Engine versions
- Visual Studio / JetBrains caches
- Blackmagic/DaVinci Resolve caches/support data
- Steam partial downloads (`steamapps/downloading`)
- WSL VHDs if Linux is now the real dev environment
- browser/app caches and `%TEMP%`

When moving files off, write a manifest with source path, destination path, size, and timestamp. Prefer moving large personal artifacts first; do not delete Windows app internals from Linux unless Semyon explicitly approves the exact path.

## VM and dual-boot guidance

For Semyon's use case, keep the bare-metal Windows install boring for Fortnite/anti-cheat. Do not routinely boot that same Windows installation both bare-metal and as a VM disk unless there is a strong reason; it can cause driver churn, activation/BitLocker weirdness, and anti-cheat suspicion.

Better layout:

```text
1TB fast NVMe:
  Windows shrunk to ~250-350GB for Fortnite/rare Windows gaming
  Linux LUKS+Btrfs in remaining space

500GB SSD:
  VM images
  shared paperwork folders
  scratch/backups
```

For Codex/Computer Use paperwork, create a separate Windows VM with its own virtual disk and shared folders rather than using the Fortnite Windows disk. This lets Codex control the VM desktop while Linux stays usable, and keeps anti-cheat Windows clean.

Before raw-disk passthrough of any Windows disk, if explicitly requested:

- Ensure Windows Fast Startup/hibernation is off.
- Ensure NTFS is clean.
- Disable/mask any Linux automount of the disk.
- Back up important data.
- Use whole-disk passthrough via stable `/dev/disk/by-id/`.
- Use UEFI/OVMF.
- Do not play anti-cheat games in the VM.
