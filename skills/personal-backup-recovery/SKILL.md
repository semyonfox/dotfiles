---
name: personal-backup-recovery
description: "Use when design and operate Semyon's selective personal backups, offsite restic repositories, recovery verification, and data-retention boundaries."
version: 1.0.0
created_by: agent

metadata:
  harness: [hermes]
---

# Personal Backup and Recovery

Use for Semyon's NAS, server, PC, application exports, restic/B2 offsite protection, recovery audits, retention, and restore drills.

## Principles

1. Inventory and classify before copying or deleting. A broad NAS/user directory is not automatically a backup set.
2. Separate **live/canonical data**, **application exports**, **archives/device dumps**, and **backup copies**. A backup is not a filing system.
3. Use explicit allow-lists for offsite data. Do not back up other users' data or paid/reacquirable media without an explicit decision.
4. Preserve raw device dumps as provenance/recovery sources. Promote hash-verified unique material to a canonical destination before treating it as routine offsite input.
5. Do not copy live database data directories. Make and validate application-native/logical exports.
6. Do not call a job healthy merely because it uploaded data: require a completed snapshot, repository check, and targeted restore test.

## Source-selection workflow

1. Produce a read-only inventory by owner, top-level path, apparent/allocated size, file count, and sensitivity.
2. Classify each candidate: `canonical`, `duplicate`, `archive`, `cache`, `cloud-synced`, `generated`, or `review`.
3. Include only irreplaceable selected sources: personal documents, local-only project source/assets, current application exports, selected recovery bundles, and explicitly chosen originals.
4. Exclude by default: Arr/downloaded media, caches, thumbnails/transcodes, render cache, build outputs, package caches, `node_modules`, whole Git clones with a usable remote, historical device dumps, nested backup copies, cloud-sync replicas, and other users' data.
5. For Git-backed code, prefer a compact recovery bundle containing no-origin repositories plus verified dirty/untracked source material, instead of a complete working tree.
6. Keep a concise manifest/README beside each curated source or archive recording provenance, canonical location, selection reason, hash/check date, and offsite coverage.

## Windows-to-Linux laptop migration

Treat a migration as two independent recovery products, never as one copy operation:

1. **Whole-disk rollback image.** From a Linux live environment, identify source and target disks with `lsblk` before mounting or copying. Save an exact offline image of the entire old OS disk (EFI, recovery, OS and data partitions) to a destination with more free space than the source disk; then write and retain a checksum. This is the rollback path, not the convenient file browser.
2. **Normal-file migration staging.** Copy an explicit set of user data to a readable destination (NAS or a dedicated writable USB partition): Desktop, Documents, Downloads, Pictures, Music, Videos, Saved Games, browser exports/profile archive, app inventory, and app-specific game/project data. Keep it in a dated migration root with a small README and file manifest.
3. **Fresh install, then restore selectively.** Do not copy `Program Files`, the entire Windows profile, or application caches as an attempted “app migration.” Reinstall native/Linux apps, then restore documents and only the specific data/configuration that has a known destination.

### Live-environment safety and verification

- A flashed ISO partition is boot media, not general file storage. Use a NAS, a second drive, or a known writable data partition (for example a Ventoy utility/data partition) for migration data and images.
- Mount Windows volumes read-only for discovery/copying first. Do not run the target installer or erase partitions until the image has completed, its checksum has been written, and representative staged files open correctly.
- SSH assistance into a live environment is appropriate only with explicit device-owner authorisation, LAN-only temporary access, and a confirmed source/target disk map. Do not expose a password in a group chat; prefer a temporary SSH key. Do not run image/write commands until the exact disk identities and free space are verified.
- When monitoring a long-running remote image/hash, report only verified process/file state. Background watch notifications may return to the agent rather than appearing as user-visible chat posts, so do not promise automatic periodic channel updates unless the delivery path is actually confirmed.
- OneDrive Files On-Demand locations can appear as Windows reparse points that a Linux NTFS mount cannot traverse. Their cloud contents are not an independent local-file backup merely because the link exists. Preserve the disk image, archive the app configuration that names the vault/location, and verify that the user can sign into the relevant OneDrive account after migration. If an offline copy is required, materialise/copy the folders from Windows or download them from OneDrive before wiping Windows.
- For Minecraft and launcher-based games, preserve the launcher instance/configuration directories and saves rather than relying on a generic Documents copy. For Steam/Epic, preserve user/save/config directories but normally reinstall game binaries.

## Laptop-to-NAS Restic repositories

When Semyon asks to protect a named laptop "to the NAS", treat the laptop as the Restic client and inspect it first; do not assume Restic belongs on the NAS. Build a per-device encrypted repository below the owner’s NAS namespace, for example `/nas/users/<user>/restic/<hostname>`, and use a persistent NFSv4 automount with `_netdev,nofail,x-systemd.automount` rather than a fragile ad-hoc mount.

1. Before claiming protection, distinguish three independent layers: (a) the laptop’s Restic repository on NAS, (b) NAS-local Btrfs snapshots, and (c) genuine offsite replication. Inspect the actual NAS snapshot script, current daily/weekly/monthly snapshot directories, and execution log. A server job named "backup" that copies server data to NAS is not evidence of Backblaze/B2 or other offsite coverage.
2. On the client, install `restic` and `nfs-utils`, mount the user export, initialize the repository as the laptop user, and store its generated password in a `0600` local file. For user-systemd timers deployed through GNU Stow, verify actual boot persistence—not just `systemctl --user enable --now` or a `linked` unit state. A Stow-folded `timers.target.wants` directory symlink may not be scanned as a systemd wants directory: require `systemctl --user show timers.target -p Wants` and `list-dependencies timers.target` to include the timer. If absent, deploy `timers.target.wants` as a real directory containing the timer symlink (use Stow `--no-folding` or an equivalent explicit layout), then daemon-reload and verify the next trigger. Make recovery possible: have the password escrowed in the user’s password manager or another separately protected recovery channel; never put it inside the repository. Keep device sudo credentials distinct from Restic encryption passwords. Never request, paste, or echo repository passwords, B2 keys, Bitwarden session tokens, or vault passwords in group chat. Do not feed secrets through an echoed PTY; use a protected local prompt or non-echoing secret channel. If one appears in a group channel, stop treating it as private and have the user revoke/rotate it after the immediate recovery work.
3. Use a curated allow-list, not a whole-home backup: documents, photos/media, selected Downloads, personal configuration/keyrings, and game-save/config locations. Exclude caches, Flatpak payloads, package/game downloads, Minecraft assets/libraries, and old migration archives by default. For Prism, include each instance’s `minecraft/{saves,screenshots,config}` and options—not global libraries. For Steam, include `userdata`; retain Proton `compatdata` only when needed as save-location insurance, then refine after a save-path audit.
4. Do not enable the recurring user timer until a manual first snapshot, `restic check`, and at least one actual restore plus SHA-256 comparison pass. Use a user systemd timer with `Persistent=true`, randomized delay, and a low I/O priority after the manual path is proven. **Audit old green timers skeptically:** inspect the actual runner and its journal/log output, require `command -v restic`, and verify a real `restic snapshots` result. A script that pipes `restic ... | tee` without `set -o pipefail` can log `restic: command not found` yet exit 0 and make systemd report a false successful backup. Use `set -euo pipefail` (or capture and propagate the Restic exit code) and never print a completion message after a failed backup/prune.
5. Before initializing a client repository, verify the mount from that client—not merely an `/etc/fstab` entry: `findmnt -T <mount>` must show the intended NFS source, the mount directory must exist, and the laptop user must be able to create a test directory in its intended owner namespace. Compare numeric UID/GID and NAS ACL/group ownership when NFS AUTH_SYS is used; a missing automount or an ownership mapping mismatch must be repaired before assuming the Restic path is writable. Remove only the explicitly created test directory after validation.
6. When a root-owned installer triggers the first backup, execute the backup process as the laptop owner with an explicit target home (for example `sudo -u "$user" -H ...` or `env HOME="$home_dir"`). This preserves repository ownership and makes `$HOME`-based password/source paths deterministic.
6. Shell backup scripts commonly use `set -e`; helpers for optional paths must always return success when a directory is absent. Prefer `if [ -e "$path" ]; then ...; fi` over a bare `[ -e "$path" ] && ...`, otherwise the first missing optional source can silently abort the initial backup.
7. Match NFS mounts by the filesystem family, not only the literal `nfs`: `findmnt -T <mount> -n -o FSTYPE | grep -q '^nfs'` accepts normal `nfs4` mounts. A strict `grep -x nfs` rejects a healthy NFSv4 mount and creates a false backup failure.
8. Size a user service's `TimeoutStartSec` for the first full seed, not an incremental run. A large curated source can commit a valid snapshot while a too-short systemd timeout later terminates the process and leaves a stale Restic lock. Before `restic unlock`, confirm the recorded writer PID is absent; then unlock, run `restic check`, and perform the staging restore/hash proof. Set a generous bounded timeout (for example 12h for a large laptop seed) before relying on the timer.
9. Treat Backblaze/B2 setup as a separate cost/credential-bearing action. Inspect active `rclone`/Restic configs, user scripts (including `~/scripts` and project backup directories), systemd units, cron, and journal history for an actual B2 remote before saying offsite exists; do not infer it from NAS snapshots, a Google Drive remote, or a local server-to-NAS job. When layering device → NAS → B2, deliberately stagger schedules so each consumer sees a completed source snapshot rather than racing concurrent writes.

## B2 disaster-recovery topology and audit

### Choose repository boundaries before bucket boundaries

For a low-interaction household DR setup, prefer **one B2 bucket with multiple named Restic repository prefixes** unless there is a genuine ownership, credential, legal, or blast-radius reason for separate buckets. Bucket count does not materially change pay-as-you-go storage cost; selected data, retention, retrieval, and transaction patterns do.

A useful baseline is:

```text
b2:<bucket>:immich          # application-specific source and DB exports
b2:<bucket>:nas-core        # explicit allow-list of important NAS data
b2:<bucket>:<device-name>   # individual laptop/device recovery set
```

Keep high-churn application data, curated documents/configuration, and per-device recovery data in separate repositories where they need different retention, verification, or recovery boundaries. This sacrifices cross-repository deduplication but makes the DR system understandable and lifecycle-safe.

### Never nest a Restic repository in a normal Restic source set

Do not include a local Restic repository (for example `/nas/users/<user>/restic/<hostname>`) inside a broad `nas-core` backup. Its encrypted packs are opaque, change with repository metadata, and an outer backup is a poor substitute for repository-aware replication.

For a laptop whose primary repository lives on NAS, use `restic copy` to replicate its snapshots into a distinct B2 repository. Schedule it after the local snapshot window; exclude its local repository path from all broad NAS source manifests. `restic copy` is repository-aware, but with different source/destination keys it must read and re-encrypt copied data; the first copy therefore reads the full selected local snapshot and uploads it to B2. It does not re-chunk data, so do not expect cross-repository deduplication. This is appropriate for server-managed offsite replication, but capacity/bandwidth estimates must include that first full copy.

**Server-managed copy preflight:** inspect the NAS-local source repository structurally before enabling a `restic copy` timer. A `config` and `keys` file merely prove initialization. If pack files exist but `snapshots/` and `index/` contain no files, treat it as an interrupted/unfinished first seed—not a recovery point and not a source to copy. Do not delete its packs or lock during an audit. Instead, obtain the source repository password, complete a clean laptop-to-NAS snapshot, run `restic check`, and staging-restore/hash-verify a representative file. Only then initialize the distinct B2 target, manually copy, validate the B2 target with `check` plus restore, and enable the scheduled copy. Keep source and destination passwords in separate `0600` files and escrow them outside both repositories.

### Audit existing B2 before extending it

A B2 Restic environment file proves only that a target once existed. Before calling it healthy or piggybacking a new source:

1. Enumerate snapshots and record count, paths/tags, and newest timestamp.
2. Run a non-destructive `restic check`.
3. Inspect user/system timers, cron, scripts, and journal history for the job creating snapshots. A clean repository with no active scheduler is stale/manual, not automated DR.
4. Confirm source paths; an application label alone is not coverage evidence.
5. Redact credentials and target known Restic/Rclone config and service paths; avoid broad content scans that can expose unrelated tokens.

### Low-noise operating cadence

Restic re-stats source metadata and performs B2 metadata/index operations each run, but unchanged file contents are not re-uploaded. For curated DR sources, this is normally modest after the initial snapshot.

- Use daily/on-availability incremental snapshots.
- Run metadata checks periodically; rotate `check --read-data-subset` instead of reading all B2 data daily.
- Preview retention with `forget --dry-run`; run `prune` outside backup windows because it locks the repository and can be expensive/slow.
- Require a real B2 restore test, not just a successful upload.

## Automation and atomic publishing

### Application-specific B2 jobs

A deployed Restic runner is not automated protection until its scheduler is both **enabled and active**. For application-aware sources such as Immich, preserve the runner's correct sequence: generate a fresh logical database export from the live service, validate it with the native tool, hash the export and recovery configuration, then snapshot the managed originals plus that timestamped recovery bundle. Do not copy live database directories.

1. Inspect both the runner and all user/system timers, cron files, and journal history. Search `~/scripts` and backup-project directories as well as standard unit locations; a sound runner may exist with no timer.
2. Install a user `Type=oneshot` service and `Persistent=true` timer only after a successful manual run. After `enable`, explicitly start or use `enable --now` for the timer and verify it is `active (waiting)` with a real next trigger; `enabled` alone is insufficient.
3. Require a completed B2 snapshot, `restic check`, and an isolated restore of the new logical dump/config bundle. Validate hashes and run the database-native listing/inspection command against the restored dump before reporting the application offsite layer healthy.
4. If an application container is absent or degraded, first capture a pre-change Docker baseline (containers, relevant inspect data, and unhealthy-service logs), then recreate only the documented affected Compose services using the correct env file. Verify actual API health and container health after a bounded grace period; do not use a successful `compose up -d` exit alone as proof.

### Server-to-NAS snapshot publication

A server backup that mutates its only `current/` tree is unsafe: an interruption can leave a mixed tree that looks recent but has no trustworthy completion state. Build server-to-NAS jobs as:

```text
timestamped staging directory → data transfer → manifest + required-path validation
→ checksum manifest → COMPLETE marker → publish generation → atomically repoint current
```

Keep the last known-good published tree until staging succeeds. Treat a missing `COMPLETE`, stale manifest, or a SIGTERM/non-zero run as an incomplete recovery point even if some files were transferred. For privileged host configuration, use a narrowly scoped exporter or explicitly report skipped files; do not mask permission errors and then claim a complete host recovery set.

#### Migrating a legacy mutable `current/` tree

Do **not** delete or clear an existing `current/` directory at job start. First create and validate a new staged generation. Only after it is complete, retain the old directory as `generations/legacy-current-<timestamp>` and replace `current` with a symlink to the new generation. Later runs can replace that symlink with one same-filesystem rename. This protects the known-good point through the first redesign run.

For filesystem-copy generations, use `rsync --link-dest=<verified-current>/home-...` only when the prior target has both a non-empty manifest and `COMPLETE` marker. It preserves distinct restorable generations while avoiding a full additional copy of unchanged data. Measure destination free space before the first seed and allow for changed-data plus staging headroom; apparent source size is not the additional Btrfs/NFS use.

A Wi-Fi-backed server→NAS seed may run for hours. Size the service timeout accordingly, keep the existing recovery point intact, and verify only after it exits: successful unit result, `current` resolves to a completed generation, manifest hash equals the marker value, required recovery files exist, and a staged/read-back file matches its source hash.

## Raw disk-image imports already retained on NAS

When a whole-disk rollback image is imported from USB to a user NAS subvolume, establish the required recovery layers before starting Restic:

```text
NAS raw image + NAS Btrfs snapshots  # local rollback/versioning
B2 Restic repository                 # encrypted off-site recovery copy
```

- If the raw image will remain on NAS and B2 is the intended off-site layer, back it up **directly to the B2 Restic repository**. Do **not** first seed it into a NAS-local/laptop Restic repository and then run `restic copy`: that makes a second large encrypted NAS copy without adding an independent recovery layer beyond the raw image plus Btrfs snapshots.
- The laptop → NAS → B2 `restic copy` topology remains appropriate for an actual laptop's curated primary repository; it is not the default for a one-time NAS-resident disk image.
- Before an import, inspect the destination Btrfs subvolume quota (`btrfs subvolume show <path>`). Filesystem-wide free capacity can be ample while a user qgroup referenced limit causes `Disk quota exceeded`. Change a quota only for the requested image plus existing user data and appropriate headroom.
- Mount USB media read-only; use resumable `rsync --partial --append-verify`; compare the full destination SHA-256 against the recorded source digest; then write a destination-relative checksum manifest.
- If an interrupted/mistaken NAS-local Restic seed has no intended snapshot, do not remove packs manually. Confirm retained snapshots, remove the stale lock only after the writer has stopped, run `restic prune --dry-run`, prune verified unreferenced packs, and run `restic check`.
- For the direct-B2 recovery proof, require the completed snapshot and `restic check`, then restore/read back the small SHA-256 manifest from B2. The full USB→NAS digest comparison proves the local image; avoid an unnecessary full 200+ GiB B2 restore unless the user requests the time and retrieval cost.

## Restic operation

- Prefer separate repositories/prefixes for high-churn application data and curated recovery data when they need different retention, verification, and failure boundaries. A shared repository has cross-set dedupe; separate repositories provide cleaner lifecycle control.
- Tag snapshots by source role and use an explicit, documented `--group-by` scheme consistently for backup and retention.
- Run `restic check` regularly. Rotate `check --read-data-subset` or schedule full read-data validation over time.
- Preview retention with `restic forget --dry-run`; run `prune` outside backup windows and check the repository afterward.
- Treat a restic exit code `3` as a partial snapshot: identify the exact unreadable path, repair only that anomaly, then take and restore-test a follow-up snapshot.
- Timestamped export directories change backup paths and can defeat default parent selection. Use a stable atomically published input path or explicitly choose a verified parent snapshot. Expect NFS metadata scans even when unchanged content is not uploaded.

## Application and media rules

- Immich: preserve its managed `library` and `upload` layout plus a validated database export. Never manually migrate upload files into library. Exclude only known regenerable derivatives after verifying the active layout.
- Resolve: distinguish Project Library backup, logical DB dump, `.drp` export, and `.dra` archive. Before restructuring project media, create and validate a Resolve-native recovery point. Cache, optimized media, proxies, and final renders need separate classification; do not delete them by path name alone.

## USB recovery-image import into a NAS user namespace

When a recovery USB is attached directly to the NAS and its disk image must live under another household member’s `users/<owner>/` namespace and receive B2 protection, treat physical import and Restic coverage as independent, verifiable stages.

1. **Identify the actual host first.** Inspect the server’s NFS mount separately from the NAS’s block-device/mount inventory. A USB attached to the NAS will not appear in the server’s `lsblk` output.
2. **Preflight privilege, quota, and ownership before promising a copy.** Confirm the removable partition is mounted, inspect it read-only, verify write access to `/mnt/storage/users/<owner>/`, and inspect its Btrfs subvolume/qgroup (`btrfs subvolume show`). Filesystem free space is insufficient: a small `Limit referenced` can make `rsync` fail with `Disk quota exceeded` despite terabytes free. An owner-only namespace requires NAS-local privileged or owner-context copying; never weaken its permissions just to let a server account write there. If the requested image needs it, raise the precise qgroup limit to cover the image, existing data, and modest headroom, and report that durable capacity-policy change.
3. **Mount removable media read-only for discovery** with `nosuid,nodev,noexec`, then identify the actual image by extension and size. Do not infer the image path or partition layout from a USB label, and never mount an unknown disk image as a filesystem.
4. **Import without deleting the USB source.** Copy to a stable, descriptive `disk-images/` or dated recovery directory with resumable `rsync --partial --append-verify`; preserve the raw image; calculate SHA-256 on source and destination; and require an exact match. A migration checksum manifest may name its original absolute USB mount, so compare its recorded expected digest to the destination digest and publish a destination-relative manifest after verification. Retain the USB source until the B2 restore test passes.
5. **Choose the off-site topology deliberately.** A laptop’s normal Restic include list will not automatically capture a loose image placed in its NAS directory. If the NAS raw image and Btrfs snapshots are retained as the local layer, snapshot the image explicitly **directly to B2** with an identifiable role/tag—do not create a second NAS-local Restic copy just to relay it to B2. Use NAS-local Restic → B2 `restic copy` only when that local repository is itself the intended primary recovery product. If a server-run Restic identity needs a private owner subvolume, grant only per-directory/image traverse/read ACLs; do not make the archive generally readable.
6. **Verify the actual B2 input.** Enumerate B2 afterward and verify the new snapshot/tags. An enabled/waiting timer and an older matching snapshot prove historical automation, not coverage of the imported image.
7. **Require a B2 recovery proof.** For an exceptionally large image, read back or restore the SHA-256 manifest from B2 and compare it with the verified NAS digest; use a full-image B2 staging restore only when explicitly requested. Report separately: USB→NAS hash, B2 snapshot ID, and restore/read-back result.

### Privilege-bound NAS imports

Never request or accept a NAS sudo password in group chat. If noninteractive privilege is unavailable, state the exact safe boundary (for example, the read-only USB mount or copy into an owner-only namespace) and ask the user to run the minimum interactive NAS-local command. Resume with discovery; do not guess the USB path or image filename. When an offsite-copy unit resides under `~/.config/systemd/user/`, inspect it with `systemctl --user`, not the system manager.

Once the user has supplied a clear, authorised operational scope, act decisively and report concise verified progress. Do not turn ordinary storage/import work into repeated confirmations or extended safety lectures; reserve interruption for a real ambiguity, privilege boundary, or destructive-scope change.

## First-offsite-snapshot checklist

1. Verify source paths and ownership/permissions.
2. Create and validate fresh DB/config exports; hash recovery inputs.
3. Run the snapshot and require a clean completion.
4. Run `restic check`.
5. Restore one source/original file and compare SHA-256.
6. Restore one database/config item and validate it with the native tool.
7. If an initial attempt failed, run `restic prune --dry-run`; prune only verified unreferenced packs, then re-run `check`.
8. Schedule backup, retention, staleness/failure alerting, and periodic restore drills only after the manual path has passed.

## References

- `references/selective-offsite-and-first-snapshot.md` — detailed restic/B2, preservation, and Resolve evidence/pitfalls.
