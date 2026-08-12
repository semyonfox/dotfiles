---
name: personal-data-protection
description: "Use when design, operate, verify, and restore Semyon's local and offsite backups for NAS, Immich, servers, devices, and recovery archives."

metadata:
  harness: [hermes]
---

# Personal Data Protection

Use for backup design, disaster recovery, restic/B2 setup, NAS recovery, Immich protection, archive consolidation, restore testing, retention, backup-provider comparisons, or any request to decide what data matters and where it should live.

## Goals and boundaries

Build layered, understandable protection:

```text
live data → local recovery copy/snapshot → encrypted offsite copy → proven restore
```

- Treat RAID and NAS snapshots as local availability/rollback, never as offsite backup.
- Use explicit allow-lists. Do not back up a whole NAS, home directory, snapshots, downloads, cache, transcodes, dependency trees, or historical device dumps merely because they exist.
- Keep recovery mirrors, application-consistent DB exports, and cold archival sources distinct from canonical live data.
- Preserve secrets by keeping access keys/repository passwords out of chat, Git, shell history, reports, and logs. If a secret is exposed in chat, replace it before a production repository is initialised.

## Safe workflow

1. **Discover before copying.** Verify the live service, canonical sources, data-owner boundaries, current local recovery points, mount topology, and provider credential readiness.
2. **Classify sources.** Include unique photos/videos, documents, code, user configuration, selected project media, and database-native exports. Exclude rebuildable cache, thumbnails/transcodes, Arr media/downloads, build outputs, package stores, temporary logs, and device dumps until their unique content is promoted.
   - **Semyon-specific offsite scope:** default to only Semyon's curated material. Do not upload Adam/family data merely because it is visible on the NAS. Do not include whole dotfiles repositories or Git clones because they exist: inspect Git origin and dirty status, then preserve only no-origin projects plus compact recovery material for local-only/uncommitted work (tracked patch plus non-ignored untracked source), excluding `node_modules`, builds, Git object history, and caches.
   - **Resolve selection:** separate live hosted database dumps, canonical source assets, caches/renders, and migration archives. Exclude `CacheClip`, gallery/cache trees, legacy recovery/refactor trees, and duplicate local daily/weekly/monthly retention copies. Select the current verified hosted-library native dump and only SHA-verified canonical project assets; do not assume scattered historic media has already been semantically consolidated.
   - **Nested retention pitfall:** if a source already maintains `last`/daily/weekly/monthly copies, do not back up every duplicate to restic by default. Select the validated current export and let restic’s own snapshot/retention policy carry the offsite history.
   - **Seed placement:** map the actual data route. A Wi-Fi server reading NAS data over NFS may force source bytes over Wi-Fi before sending the backup over Wi-Fi again to the WAN. If the NAS is on a faster wired link and WAN upload is the limit, run the sustained restic agent on the NAS after explicitly checking source paths, credential handling, and recovery ownership.
   - **Immich staging imports are a two-phase deletion case.** Upload with source deletion disabled; let Immich’s content-hash dedupe report accepted/new versus existing assets. For human collections, use one explicit `--album-name` per collection rather than an accidental flood of folder albums. After every requested batch completes, re-run the upload client in dry-run mode over the exact source tree and require **zero new assets** before deleting that source tree. Compare the client’s recognised-asset count with a filesystem type inventory: local byte-identical files may be collapsed before the client reports its received count, while non-media, unsupported, ignored, or hidden files can also make counts differ; verify relevant subtrees rather than inferring loss from one root summary. Preserve an import/deletion receipt and retain sources while an upload is active. Exclude and investigate any sparse/zero-block media file whose logical size is implausibly larger than its allocated blocks; do not ingest an apparent multi-gigabyte hole merely because it has an `.mp4` extension.
3. **Protect mutable applications correctly.** Never rely on a raw copy of a live PostgreSQL directory. Create a native dump, parse/restore-list it, hash it, and publish atomically with restricted permissions. Even after an offsite run starts, retain a small rolling set of validated native dumps until repository integrity and a disposable restore have passed; RAID and same-NAS snapshots are local rollback, not a substitute for an application-consistent database recovery point.
4. **Do not manually rearrange application-managed storage.** Use an application’s own migration/organisation tooling only after an initial protected snapshot exists. Take before/after backups for large migrations.
5. **Deploy offsite deliberately.** Use restic with client-side encryption, restricted bucket-scoped credentials, and a repository-specific password stored in Vaultwarden plus a restrictive local file. Install/configure only after the user has completed provider account/payment/2FA steps.
6. **Prove recovery.** A successful upload is insufficient. Run repository integrity checks and restore representative files/database exports into a disposable target, then validate hashes or parser output.
7. **Automate only after the first restore.** Add timers, retention, stale-last-good alerts, failed-check alerts, and capacity checks. Report an absent completion marker or restore proof as not protected.

## Archive and dedupe safety

- Start with SHA-256 evidence and path-preserving Btrfs reflinks; physical dedupe is not semantic consolidation.
- Never call logical reflinked bytes exact disk space reclaimed without Btrfs exclusive/shared allocation measurements.
- Promote verified unique source content to canonical locations before pruning recovery dumps.
- User approval for cleanup does not turn uncertain VM disks, game saves, Docker/config state, dotfile conflict copies, or named source archives into cache. Confirm canonical copies first.
- When a potentially important deletion is discovered, stop competing NAS writes where safe, search canonical and recovery roots, and run full content verification before declaring recovery safe.

## Provider selection

Prefer retrieval from official provider documentation before quoting live prices, platform support, regional placement, retention, retrieval, egress, or storage-class terms. Evaluate the actual source host, data volume, restore workflow, and OS—not headline "unlimited" storage claims.

For Semyon's current Immich/NAS use case, read `references/immich-b2-offsite-backup.md` before selecting/configuring a provider. For staged-client uploads, duplicate verification, safe source/archive pruning, and Btrfs-space interpretation, use `references/immich-staged-import-and-legacy-prune.md`.

## Reporting

Lead with what is protected, the last proven restore, and the remaining gap. State exact source paths, service names, and provider region when useful. Never describe a same-NAS copy or a merely running backup job as a completed offsite backup.
