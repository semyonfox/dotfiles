---
name: self-hosted-photo-library-operations
description: "Use when importing to self-hosted photo libraries."
version: 1.0.0

metadata:
  harness: [hermes]
---

# Self-hosted photo-library operations

## Scope

Use for safe administration of self-hosted photo/video libraries such as Immich: service-health checks, bulk imports, per-user ownership, NAS-backed storage, deduplication, and source cleanup.

## Operating sequence

1. **Identify the three layers separately.** Confirm the application/API host, database/cache services, and raw managed-storage root. Never treat a NAS path containing managed library data as an import source.
2. **Verify the application layer, not just dependencies.** A healthy database/cache does not mean imports work. Check the main server and ML/worker containers plus their exit state before launching an import.
3. **Diagnose stopped GPU-enabled services first.** If a container is stopped with an OCI/NVIDIA library-mount error or exit `127`, inspect the actual host driver with `nvidia-smi` and the container's `docker inspect` error before changing packages. After a driver update, containers can retain an old mounted library path (for example `libEGL_nvidia.so.<old-version>`) while the installed driver is already current and healthy. Back up the stack file, recreate only the affected services with the real Compose env file (`docker compose --env-file stack.env -f stack.yaml up -d --force-recreate immich-server immich-machine-learning`), then verify container health and `GET /api/server/ping`. Do not reinstall or downgrade a working current driver just to address stale container mounts.
4. **Create media-only staging roots per person.** Keep each user’s photos and videos in a distinct staging root and import under that user’s account/API credential. Never ingest broad home directories, Restic repositories, disk images, documents, or application backups.
5. **Use the application’s supported import route.** For Immich CLI, run `immich upload -r --dry-run <source>` separately for each account first; use the matching per-user API key, bounded concurrency for USB/NAS paths, and only then use `--delete` if the user approved source removal. Let the library calculate duplicates and metadata. Do not copy files directly into its managed upload/library layout or alter its database.
6. **Verify before cleanup.** Record source file count/bytes, import result counts, duplicates/skips, and a post-import API/library check. Compare the account/library asset-count increase with the reported newly-uploaded count. Some CLI versions leave files already identified as pre-existing duplicates in place even with `--delete`; remove those only after the dry-run/import output has explicitly classified them as duplicates for the same account. Delete only the explicitly approved staging source after confirming it was safely ingested; retain canonical originals and recovery artifacts unless their redundancy was independently verified.

## Safety checklist

- Preserve user separation; do not upload another person’s media into the wrong account.
- Redact API keys, database credentials, and tokens.
- Back up project/configuration state before changing stack GPU or mount settings.
- If a source is encrypted or opaque (for example Restic), restore selected media to a fresh staging directory first; never point the importer at repository internals.
- If filenames collide, rely on application-level dedupe plus content verification—not names alone.

## Verification evidence

Report: container health, actual staging path, source inventory, user/account targeted, import success/duplicate/error counts, and the exact source cleanup scope. Do not claim an import is complete from a submitted job alone.
