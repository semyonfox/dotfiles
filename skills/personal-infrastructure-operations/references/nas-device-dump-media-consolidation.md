# NAS device-dump consolidation and Immich staging

Use for Semyon's recovered device dumps and `backups/laptop/linux_ingress` when promoting personal media/documents into canonical NAS folders.

## Safety model

- Treat the newest device-home snapshot as the primary candidate and ingress `copied/` trees as older mirrors only after content verification.
- Do not merge code, game installs, package/tool caches, agent state, secrets, VM data, or whole home directories in a bulk content pass.
- Never overwrite a canonical destination solely by pathname. Hash first; preserve differing collisions in a dated conflict subfolder.
- For a cross-subvolume move, copy/reflink first, SHA-256 verify source and destination, then remove the source. Write a JSON manifest.

## Categorize before moving

Safe first-pass categories:

- `Documents` -> `users/semyon/documents/imported-from-<source>-<date>/`
- `Music` -> `users/semyon/music/`
- wallpapers -> `users/semyon/pictures/wallpapers/imported-from-<source>-<date>/`
- lectures/papers -> dated subdirectories under `users/semyon/documents/university/`
- actual recordings -> `users/semyon/videos/`, after hashing against existing canonical videos.

Keep phone camera media in a dedicated Immich staging directory rather than merging it into generic videos/pictures.

## Immich procedure

1. Verify Immich services are healthy and use `immich server-info` with existing secured CLI config.
2. Stage only supported original media extensions. Preserve source-relative paths and skip non-media sidecars.
3. Run the CLI **dry-run** first:

```bash
IMMICH_CONFIG_DIR=~/.config/immich \
  immich upload --dry-run --recursive --json-output <staging-root>
```

4. The CLI and server use content hashes: duplicate assets are skipped by default. Do not pass `--delete` or `--delete-duplicates` during review/staging.
5. If a combined staging tree appears to omit folders, dry-run each top-level source separately and record each result. Hidden `.thumbnails` folders are normally ignored by the CLI; they are app-generated preview cache, not original media.
6. Do not upload merely because staging/dry-run completed. Keep user-reviewed screenshots/photos staged until explicitly authorized.

## Repeated laptop vs ingress trees

- Use SHA-256 equality, not matching file counts/sizes, before deleting a mirror.
- If the latest-device file is already byte-identical to a canonical file, remove only the redundant staging/dump copy.
- For a different-content collision, retain both under a clear dated conflict path; report it instead of guessing which version is authoritative.

## Verification/reporting

Report exact files/bytes moved, verified duplicates removed, conflict files preserved, skipped sidecars, and the manifest path. State separately whether data was merely staged, dry-run checked, or actually uploaded to Immich.
