# Windows/Linux dual-boot workstation with Codex paperwork VM

Use when Semyon wants to keep Windows for anti-cheat games while using Linux as the main dev OS and still run Codex/Computer Use for GUI paperwork, PDF signing, or browser+desktop workflows.

## Pattern

Prefer three separated roles:

1. **Linux main OS** — daily/dev environment, primary shell/projects.
2. **Bare-metal Windows** — kept clean for games with strict anti-cheat (e.g. Fortnite). Do not rely on VM passthrough for those games.
3. **Disposable Windows VM** — Codex/ChatGPT desktop + Computer Use + PDF tools for paperwork/signing, so Codex can control the VM foreground without taking over Linux.

This is usually safer than booting the same physical Windows install both bare-metal and virtualized.

## PC inventory observed in session

Semyon's PC (`semyon-pc-cachy`) at time of inspection:

- CPU/RAM: Ryzen 5 5600G, 32 GiB RAM, AMD-V available, KVM AMD module loads.
- Current Linux disk: ~500GB SK hynix NVMe (`nvme0n1`), 4GB vfat `/boot`, LUKS + Btrfs root/home/cache/log subvolumes, Limine boot.
- Windows/gaming disk: 1TB WD_BLACK SN850X (`nvme1n1`), Windows EFI + MSR + ~930GB NTFS + recovery.
- `/mnt/windows-games` was configured as a systemd NTFS automount for the Windows partition.
- KVM-capable but libvirt/qemu/virt-manager packages were not installed yet.

Treat this as stale inventory; re-check live state before acting.

## Recommended storage architecture

If Semyon wants Linux on the 1TB while keeping Windows for Fortnite:

```text
1TB WD_BLACK SN850X
├─ Windows, shrunk to ~250–350GB
│  └─ Fortnite / anti-cheat / rare Windows use
└─ Linux main system, remaining space
   └─ LUKS + Btrfs

500GB SK hynix
├─ VM images
│  └─ Windows paperwork VM
├─ shared paperwork folders
└─ scratch/backups/general data
```

Alternative: keep Windows using the whole 1TB and leave Linux on 500GB, but that does not satisfy the “Linux on 1TB” goal.

## Safe workflow for resizing/migration

Before shrinking Windows:

1. Boot real Windows.
2. Disable hibernation/Fast Startup:
   ```powershell
   powercfg /h off
   ```
3. Suspend/disable BitLocker if present.
4. Clean up Windows storage.
5. Shrink `C:` using Windows Disk Management first, not Linux tools as the first move.
6. Leave unallocated space for Linux.

Then from Linux/live media:

1. Back up important Linux configs/home/project state.
2. Either fresh-install CachyOS/Linux into new LUKS+Btrfs space and restore deliberately, or migrate with Btrfs/rsync if exact continuity matters.
3. Confirm both Limine/Linux and Windows Boot Manager boot before repurposing the 500GB disk.
4. Only after verification, wipe/repartition the 500GB for VM/data use.

## VM guidance

For the Codex paperwork VM, prefer a normal virtual disk (`qcow2`) over raw-passing the gaming Windows SSD.

Suggested packages on Arch/CachyOS:

```bash
sudo pacman -S qemu-full libvirt virt-manager edk2-ovmf swtpm dnsmasq
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt,kvm "$USER"
```

Then log out/in, create a Windows VM with UEFI/OVMF + TPM 2.0 if needed, and share folders for:

```text
Paperwork/Inbox
Paperwork/Signed
Paperwork/Signature
```

Install in the VM:

- ChatGPT/Codex desktop app
- Computer Use plugin if available for the account/region
- PDFgear/Adobe Reader/Edge/Chrome as needed

## Raw physical Windows disk passthrough caveats

Only use if explicitly needed. For Semyon's case, it is not the preferred route because the same Windows install is used for anti-cheat gaming.

If raw-passing a Windows disk into a VM:

- Ensure Windows partitions are **not mounted** in Linux.
- Disable/mask any Linux automount for that disk first (e.g. `/mnt/windows-games`).
- Use stable `/dev/disk/by-id/...`, not `/dev/nvme1n1` names.
- Prefer passing the whole disk if booting it.
- Expect activation/driver/BitLocker churn.
- Do not use this for anti-cheat games.

## Reporting stance

Be blunt: keep the anti-cheat Windows install bare-metal, and use a separate disposable VM for AI paperwork. Do not let Codex, VM drivers, and anti-cheat share the same sacred Windows install unless Semyon explicitly accepts the risk.