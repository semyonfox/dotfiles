---
name: backup-recovery-operations
description: "Use when design, operate, verify, and document selective local/offsite backup and recovery systems."
version: 1.0.0

metadata:
  harness: [hermes]
---

# Backup and Recovery Operations

Use when planning, changing, validating, documenting, or recovering personal/server/NAS backups, especially restic/object-storage workflows.

## Principles

1. **Inventory before selection.** Do not back up an entire user home, NAS, archive, or snapshot tree by default. Build an explicit allow-list and classify archives, caches, managed storage, cloud-synced data, and other users' data separately.
2. **Separate recovery domains.** Keep application-critical assets (for example Immich), personal core data, and other users' data in distinct repository prefixes or repositories when retention, privacy, or recovery order differs.
3. **No silent scope expansion.** Report the actual active source paths, not an inferred “likely” set. Do not describe a source as hundreds of GB/TB unless it has been measured; state uncertainty plainly.
4. **Respect ownership.** Do not copy other household users' data into the operator's offsite account without their explicit opt-in and a retention/privacy decision.
5. **Do not delete archive content as rebuildable until a canonical copy is proven.** For device dumps, game folders, old project material, or media archives: locate the canonical destination and compare complete trees/hashes before pruning. Names and apparent cache/install status are not proof.

## Client OS migration (Windows to Linux or device replacement)

For a destructive desktop/laptop migration, make two distinct NAS-backed recovery artifacts **before** installing the new OS:

1. **Whole-disk image** — bootable rollback of the old system, including EFI/recovery partitions, installed apps, user data, and the original OS.
2. **Normal migration folder** — an explicit, browsable copy of the user's Desktop, Documents, Downloads, media, school/project folders, and app-specific irreplaceable data (for example Minecraft Java saves / launcher instances and selected Steam userdata).

Do not treat a full-disk image as the only migration source: it is suitable for full restoration but cumbersome for selectively retrieving everyday files. Likewise, never assume Windows applications can be migrated to Linux; reinstall native/Flatpak/browser equivalents and use service-specific sync/export for browsers and games.

- Stage both artifacts directly on a private NAS share where possible; avoid using a normally flashed live-OS USB as general file storage. Use a second exFAT drive or a deliberately partitioned/Ventoy data volume if removable storage is needed.
- A Linux live environment can mount the offline Windows disk and NAS and perform both copies. Prefer a purpose-built imaging tool for efficient, verified images; if using raw imaging, inspect disk layout, encryption/BitLocker state, destination capacity, and compression implications first. Never select a source or destination disk from inference alone.
- Verify the disk image and open representative files from the migration folder before formatting. Record any BitLocker/device-encryption recovery key before the migration.
- Treat OneDrive Files On-Demand paths as cloud-rooted data: Linux NTFS tooling may expose them as unsupported reparse points rather than browsable directories. Record note-vault paths from app configuration; sign into the relevant personal/school OneDrive accounts after migration, or make an offline copy through Windows before wipe.
- Retain the Windows image (and, where a critical Windows-only or unofficially-supported app such as Roblox is involved, a Windows dual-boot/recovery path) until the user has tested real daily workflows, hardware, and games on the new OS.
- If remote assistance from a live environment is requested, enable only temporary LAN-scoped SSH, do not collect passwords in group chat, inspect disks read-only first, and require explicit scope approval before any write/destructive command.

See `references/windows-to-linux-live-migration.md` for the concrete live-USB sequence, data categories, USB-layout pitfalls, and verification boundaries. For raw-image capacity math, OneDrive/Obsidian reparse-point handling, and stage-first restoration of Windows app data, also see `references/windows-to-linux-laptop-migration.md`.

## Managed-application data

- Preserve the application-supported recovery set, not only “obvious originals.” For Immich this includes the managed asset directories plus an application-consistent PostgreSQL dump and recovery config.
- Never treat a live PostgreSQL data directory as a file-copy backup. Use `pg_dump`/`pg_restore` or the application's documented dump mechanism.
- Do not manually reorganize directories whose paths are referenced in an application database. First establish a successful offsite snapshot and restore drill; then use the application-supported storage-template/reorganisation job.
- Exclude only proven regenerable derivatives, such as thumbnails, encoded transcodes, and ML caches, while documenting that choice.

## Restic + object storage workflow

1. Put object-storage credentials and repository password in a mode-`0600` local config outside Git, logs, and chat transcripts.
2. Validate write permission with the provider's lightweight upload-url/write probe before launching a large seed. A dashboard payment/cap change may lag; provider API write success is authoritative.
3. Initialise the repository, run the backup, then require all three before claiming offsite protection:
   - committed `restic snapshots` entry;
   - `restic check` success;
   - targeted restore of representative data (and database parse/import validation where relevant).
4. **Partial-success handling:** restic can save a snapshot while returning exit code `3` because a source file was unreadable. Treat that snapshot as incomplete. List it, capture the failed path(s), and audit the selected NAS source tree for mode/ownership anomalies. Repair only the exact anomalous path using the owning application/container or a narrowly scoped ACL—never recursively relax permissions over managed personal data. Re-run so the partial snapshot becomes the parent, then test-restores the formerly unreadable file as well as the database/config export. For `latest` symlink exports, use `readlink` and `stat -L`; plain `stat` reports the link-text size, not the backup payload.
5. An interrupted first seed has no trusted parent snapshot. It may leave partial unreferenced packs and must not be called a recovery point or used as a final-size measurement.
6. For a repository-to-repository offsite copy, use Restic's explicit current syntax rather than deprecated destination-only flags: `restic copy --from-repo <source> --from-password-file <source-password> --repo <destination> --password-file <destination-password>`. After a Restic upgrade, manually start each copy unit once and inspect its journal; an enabled timer is not proof that a deprecated CLI invocation still works.
7. Explain semantics accurately: restic scans metadata each run, reuses unchanged content from a parent snapshot, content-deduplicates changed files at chunk level, and retains old versions until `forget` + `prune` removes unreferenced content. It is snapshot/versioning behaviour, not filesystem CoW.
8. Choose retention only after the initial snapshot and restore drill. Use `forget --dry-run` before destructive retention changes; `forget` removes snapshot references and `prune` reclaims unreferenced data later.

## Systemd scheduling and operational truthfulness

A timer being enabled or a service exiting `0` is not evidence that a backup ran. Before trusting or enabling a recurring job:

1. Inspect the deployed runner and the latest journal/log output. Require strict shell failure handling (`set -euo pipefail`) and ensure every critical command failure reaches the unit exit status; a missing `restic` binary must fail the job, never log a cosmetic “complete” message. Optional-source helpers must return success when a path is absent under `set -e` (for example `add() { if [[ -e "$1" ]]; then sources+=("$1"); fi; }`), rather than ending with a bare false `[[ -e … ]]` test that aborts the whole backup.
2. Confirm the binary, repository, password-file permissions, mount/transport, and source paths from the same user account that systemd will use.
3. Run one manual seed and require the standard Restic snapshot/check/restore proof before scheduling.
4. For user units, enable the timer with `systemctl --user enable --now …`, verify its next trigger, and check whether it must run after graphical logout. Use `loginctl enable-linger <user>` only after validating authorization and explicitly verify `Linger=yes`.
5. Set `TimeoutStartSec` from measured first-seed duration with substantial headroom; a default one-hour limit can terminate a valid initial backup and leave a Restic lock. Before `restic unlock`, prove the recorded PID is gone and no backup/copy is active; then remove only the stale lock and re-run `check`/restore verification.
6. Stagger layers deliberately: device-to-NAS jobs finish before NAS snapshots; offsite copies run after the NAS snapshot window. Do not stack jobs on the same I/O path without checking duration and overlap.
7. For a rotating `current/` filesystem backup, never mutate the only known-good tree first. Write a timestamped staging tree, generate a manifest and required-path checks, then atomically publish the completed tree and its `COMPLETE` marker. A missing marker or mismatched manifest makes that generation untrusted.

### Curated personal-device defaults

Unless the owner narrows scope, include personal Documents, Desktop, original images/screenshots, game saves/configuration, selected agent/editor configuration, local-only project work, and Downloads **except** proven redownloadable installers, torrents, package/build caches, duplicate cloud replicas, and plaintext credential exports. Do not equate all Downloads with disposable material. Exclude game installs/libraries, browser/application caches, trash, generated dependencies, and rebuildable runtime payloads. Treat very large video archives as a separate canonical-originals decision rather than silently creating an expensive offsite seed.

## Recovery documentation standard

When a backup workflow is created or changed, update the tracked operations repository in the same task. The runbook must contain:

- exact include and exclude paths;
- repository identifier/region but no secret values;
- installed binary/source-controlled runner location and confirmation it matches deployment;
- fresh dump and integrity-validation process;
- how to list, find, mount, dump, and stage-restore individual files;
- full recovery order: stop broken service, restore into staging, verify paths, restore database, start services, check application health;
- a clear warning that B2/object-store browser listings contain encrypted restic objects rather than ordinary files.

## Performance and placement

Measure the actual route/interface rather than relying on assumed wired topology. If source data resides on a NAS and the backup runner reads it through NFS/Wi-Fi before uploading, running restic on the NAS can remove an extra LAN hop; the WAN upload cap still bounds the maximum. Do not migrate an active seed mid-run without an explicit decision, safe credential placement, and a plan for repository parent/snapshot grouping.

## Mounted legacy-backup inventory

When a user asks what is on a removable or utility mount, begin read-only and report only structure/health unless they explicitly ask to browse personal content:

1. Confirm mountpoint, filesystem type, free space, label/device, and top-level recovery artifacts.
2. For a raw disk image, record the image size and its sidecar checksum. A checksum sidecar may retain the *old mount path* from creation, so do **not** run `sha256sum -c` blindly. Hash the image at its current path and compare its digest to the expected digest. Use low I/O priority for large USB images.
3. A restic tree containing `config`, `data`, `index`, `keys`, and `snapshots` proves a repository exists, not that it is restorable. Before operating it, confirm no restic job is active, treat a recent lock as potentially live, then use the repository's legitimate credentials to run `restic snapshots`, `restic check`, and a staged restore.
4. Treat a missing `COMPLETE` marker on a legacy filesystem-copy generation as an unproven generation even if an image and manifest are present; distinguish "artifacts present" from "recovery verified."

## Final verification checklist

- [ ] Source scope is explicit and owned/approved.
- [ ] Local application-consistent dump is validated.
- [ ] Provider write permission is confirmed.
- [ ] At least one committed remote snapshot exists.
- [ ] Integrity check and targeted restore are complete.
- [ ] Retention and monitoring are configured deliberately.
- [ ] Tracked documentation and deployed runner are aligned.
