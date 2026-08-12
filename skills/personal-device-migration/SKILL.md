---
name: personal-device-migration
description: Safely replace a personal Windows installation with Linux while preserving user data, game/app state, rollback media, and supported remote access.
version: 1.0.0

metadata:
  harness: [hermes]
---

# Personal Device Migration

Use for a supported one-device migration from Windows to Linux where personal data, game state, school/work apps, browser profiles, and an emergency rollback path must survive.

## Core model: two recovery layers

1. Make a **file-level migration copy** for practical Linux restoration.
2. Make a **whole-disk raw image** plus a SHA-256 record for Windows rollback.
3. Keep the image on external/NAS recovery storage; do not copy it to the new internal disk unless there is explicit capacity and redundancy approval.

A computed SHA-256 is a durable integrity record for future `sha256sum -c`; it is not an independent comparison with a separate source checksum.

## Installation guardrail

Before an erase-disk installer step, inventory disks by **model, transport, and capacity**. State both the internal target and the external recovery disk clearly. Never select an installer target merely because it is called `/dev/sda` or `/dev/sdb`.

For a Linux-first gaming laptop, default to Btrfs with snapshots when supported by the chosen distribution. Do not proceed with a destructive installation until the user authorises the exact internal disk target.

## Restore by semantics, not Windows paths

Normal folders map directly:

| Source | Destination |
|---|---|
| Documents, Downloads, Pictures, Music, Videos | matching `~/…` XDG folders |
| Saved Games | `~/Saved Games` initially; identify game-specific save paths before final moves |
| `.minecraft` | `~/.minecraft` for conventional launcher data |

Do **not** copy `Program Files`, `Windows`, or an entire Windows profile to Linux. Preserve Windows-only content under `~/Migration-Archive/` rather than pretending it is native Linux state.

### Application-aware migration

- **Prism Launcher:** install first. Restore portable game content (e.g. `instances/`, icons, themes, catpacks) to the actual Linux/Flatpak data directory. Keep Windows Java binaries and path-bound settings archived rather than treating them as the primary Linux config. For world saves, prefer a self-contained copy into each intended instance’s `minecraft/saves/` over a symlink to legacy `~/.minecraft/saves`: this remains valid if the legacy tree is later archived. Before copying, stop Prism/Minecraft and compare source and destination world directories (`level.dat` identifies a world). Copy missing world names and verify them with `rsync -rltni --safe-links`; never automatically overwrite or merge same-named worlds that differ—preserve both versions and ask which is authoritative. Inspect `instance.cfg` for stale Windows Java overrides such as `JavaPath=C:/.../javaw.exe`; back up the config and restore Linux automatic Java selection before the first launch.
- **Steam:** install first. Restore `userdata` to Steam's actual data directory, then let the user sign in and deliberately resolve Steam Cloud conflicts. Preserve the source archive. For a Linux Steam consolidation from Flatpak to native, stop both clients and games first; never terminate an active game without explicit authorisation. Back up configuration excluding transient `config/htmlcache`, then merge portable `userdata` and controller settings while preserving native-client state. **Do not replace native `steamapps/libraryfolders.vdf` with the Flatpak file:** native Steam rewrites library slot `0` to its own install path on launch. Retain native Steam as library `0`, add the Flatpak data directory as a numbered additional library with its app manifests, launch native Steam, and verify both paths persist. Only then uninstall the Flatpak *application* with `flatpak uninstall --user com.valvesoftware.Steam`—never add `--delete-data`, because `~/.var/app/com.valvesoftware.Steam/.local/share/Steam` is now the retained native game library. Verify each expected manifest and game directory remains before calling the cleanup complete.
- **Obsidian:** install first. Settings can be copied to its Linux/Flatpak config directory; cloud-backed vaults should be restored by signing in to the owning cloud account. Windows OneDrive reparse points are not proof a vault was locally copied.
- **Chromium/Brave:** install the browser first. With user approval, copy the profile to its Linux/Flatpak config directory. Bookmarks, history and extensions commonly port; Windows-encrypted cookies/passwords may require re-login.
- **Epic/Fortnite/EasyAntiCheat:** archive data, but do not claim Windows-only game state is a runnable native Linux migration.
- **Office/driver/vendor binaries:** install a Linux-native replacement where appropriate; leave the original state archived.

Flatpak data usually lives under:

```text
~/.var/app/<application-id>/
```

Inspect the actual app data/config location before writing. A first launch may create the expected directory. See [Flatpak user-data mapping](references/flatpak-user-data-mapping.md) for common application IDs and portable targets.

## Verification before ejection

After every scoped transfer, run a dry-run against the same source/destination:

```bash
rsync -rltni --safe-links "$source/" "$destination/" | wc -l
```

A result of `0` means no remaining differences under that rsync mode. Then:

1. Confirm expected user data and app mappings exist on the internal disk.
2. Record internal free space.
3. Confirm the raw image and its `.sha256` remain on recovery storage.
4. Keep the recovery drive until user accounts, notes/vaults, school services, games, and basic hardware have been tested.

## Remote-support handoff

1. Install and enable OpenSSH; confirm actual LAN port reachability.
2. Add an authorised SSH key using `700 ~/.ssh` and `600 ~/.ssh/authorized_keys`.
3. Prove a fresh passwordless key-auth connection before retiring a bootstrap password.
4. If requested, install RustDesk from a verified source and launch it inside the graphical user session. GNOME/Wayland may require an owner-approved portal prompt on the first real connection.
5. Never create or disclose unattended-access passwords in a group chat. The device owner must choose manual approval vs unattended access in RustDesk security settings.

### RustDesk completion criteria

A running RustDesk process proves only that the app was launched; it does **not** prove zero-touch recovery. Report the support posture accurately:

- **Manual support:** the owner must approve the connection and, on GNOME/Wayland, may need to approve the screen-sharing portal.
- **Unattended support:** requires an owner-chosen permanent password exchanged privately, RustDesk configured to start with the graphical session, and one successful connection tested from a separate device/network.
- **Pre-login limitation:** a user-session RustDesk/Flatpak cannot access an encrypted machine at its disk-unlock or graphical login screen. Keep SSH via a separately tested private network as an administrative recovery layer where appropriate.
- RustDesk's normal public service is client-based remote access, not evidence of browser-based web-console access; do not promise web access unless the installed service explicitly provides and has tested it.

When auditing a Flatpak RustDesk install remotely, inspect only non-secret posture: installed version, running process, autostart state, permissions, and whether the stored unattended-password field is empty/non-empty. Never print the password, private key, token, or full configuration values into a chat transcript.

## Snapshot validation and expectations

Btrfs plus a Snapper root configuration is not automatically a complete snapshot regime. Verify all of the following before calling snapshots "configured":

1. Root is actually mounted as Btrfs on the intended subvolume.
2. Snapper has a root configuration and can list snapshots with owner-authorised `sudo`.
3. Determine **what creates snapshots**: timeline snapshots require both `TIMELINE_CREATE="yes"` and an enabled/active `snapper-timeline.timer`; transaction snapshots may instead be provided by a package-manager hook such as `snap-pac`.
4. Do not mistake the cleanup timer for snapshot creation; cleanup only prunes existing snapshots.
5. Identify the actual boot loader before judging boot-menu recovery integration. Do not assume GRUB or require `grub-btrfs` on systems using Limine, systemd-boot, or another loader.
6. Create and name a post-migration baseline snapshot only after accounts, data, games, and essential hardware are working; verify the restoration path separately.

Snapshots are rollback convenience on the same disk, not a replacement for the external raw Windows image or an independently verified backup.

## GNOME touchpad recovery after a Windows migration

When a migrated laptop feels "tablet-like"—especially no physical bottom-right right-click or awkward drag behavior—inspect the active GNOME user settings before blaming the kernel. The `fingers` click method makes a physical right click require a two-finger press. For a conventional laptop profile that still retains touch convenience, use the graphical user's D-Bus session and set:

```bash
export XDG_RUNTIME_DIR=/run/user/1000
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus

gsettings set org.gnome.desktop.peripherals.touchpad click-method areas
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
gsettings set org.gnome.desktop.peripherals.touchpad tap-and-drag false
gsettings set org.gnome.desktop.peripherals.touchpad tap-button-map default
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true  # preserve if user prefers it
```

`areas` restores bottom-right physical right-click; the default tap mapping preserves two-finger tap-to-right-click. Do not broadly disable natural scrolling or tap-to-click merely because the user reports an awkward trackpad—confirm those preferences separately. Verify each final `gsettings get` value. If the device is temporarily offline after a reboot, retry the same session-scoped settings once SSH returns rather than assuming the change landed.

## Dell Broadcom ControlVault 3 fingerprint readers

For Dell readers reported as `0a5c:5843` / **BCM58200 ControlVault 3**, first try the distribution `fprintd` plus `libfprint` packages and verify discovery with `fprintd-list <user>`. If it reports no device, the usual working stack on Arch/CachyOS is the AUR pair `libfprint-tod` (replaces the repository `libfprint`) and `libfprint-2-tod1-broadcom`, plus repository `fprintd`.

The Broadcom driver may flash a ControlVault firmware update on first initialization. Ensure `fprintd.service` has a sufficiently long start timeout before triggering it:

```ini
# /etc/systemd/system/fprintd.service.d/override.conf
[Service]
TimeoutStartSec=3min
TimeoutStopSec=30s
```

If an initialization/firmware update is interrupted and the USB reader vanishes, **do not keep retrying**: reboot/power-cycle the laptop first, then let the service finish with the longer timeout. Only after `fprintd-list <user>` recognizes the device should the owner run `fprintd-enroll` locally and touch the reader. Fingerprint enrollment is a physical user action; do not claim it completed remotely.

## Completion report

Report four separate facts:

- ordinary data restored and verified;
- native apps installed/mapped;
- Windows-only state retained in an internal archive;
- external raw image/checksum retained as rollback media.

Do not say “everything migrated” if cloud-only vaults, account logins, game-cloud conflict choices, or GUI portal approval remain user actions.
