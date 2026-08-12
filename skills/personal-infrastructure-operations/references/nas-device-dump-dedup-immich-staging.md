# NAS device-dump consolidation and Immich staging

Use for Semyon's large NAS recovery/device-dump trees when he wants physical dedupe, retention triage, or promotion of device media into Immich.

## Scope boundaries

- Start NAS-local and read-only. `/mnt/media` is NFS and broad client-side walks can time out or hide allocation details.
- Device dumps may contain full-home snapshots, Windows profiles, laptop ingress copies, recycle copies, credentials, personal media, agent state and other people's backups. Do not treat a directory name as its content class.
- If Semyon initially requested agents but later says **do not delegate**, cancel queued delegated/background audit work and continue direct. Do not reinterpret that as a permanent ban on delegation for unrelated tasks.
- Detect concurrent changes before moving data. If an expected source path vanished or a new audit/consolidation directory appears, inspect its manifest/logs and report the conflict; do not guess where files went or overwrite the apparent destination.

## Safe physical dedupe: retain every path

For exact duplicate device-dump files on the NAS Btrfs filesystem, prefer **Btrfs reflink/extent dedupe** over `fdupes -d` deletion:

1. Hash regular files with SHA-256 and group by `(size, digest)`; do not follow symlinks.
2. Use `FICLONE`/`duperemove` to share extents while retaining each original pathname and metadata.
3. Use a NAS-resident, checkpointed process (`nohup` or a user service), not an SSH-piped long task. A dropped SSH session can interrupt multi-hour scans.
4. Keep output compact: periodic counters plus JSON summary. Verbose `duperemove -v` can create gigabyte-scale logs.
5. Preserve/record permission-denied duplicates. They are not data loss; root access may be required to reflink archived files. Never chmod old archives merely to dedupe them.

### Measurement caveat

`reflinked_logical_bytes` / `net shared extents` is not automatically the exact new free space. A prior dedupe pass may already have shared blocks, and normal `df` cannot reconstruct historical Btrfs exclusive allocation. Capture Btrfs exclusive/shared allocation **before and after** a future run if exact reclaimed bytes are required.

## Consolidation triage

Typical canonical destinations under `/export/nas/users/semyon/` are `videos`, `pictures`, `documents`, `code`, `editing`, `project_files`, and `games/saves`.

- Promote only verified user content: camera originals, personal videos, documents, source repos, editing project assets and game saves.
- Keep one dated minimal dotfiles/config recovery archive plus current server config backup. Do not merge whole-home dump trees into a dotfiles repo.
- Treat `node_modules`, SDK/toolchains, caches, plugin markets, AI-agent runtime/cache state, Git metadata, downloads and portable game installs as archive-only or discard candidates, not canonical data.
- Same file count and size is suggestive, not proof. Use SHA-256 results when choosing a canonical source. For mirrored laptop copies, choose the documented latest full-home snapshot as the source and retain the other as archive until promotion verification succeeds.
- Do not move another person's backup into Semyon's canonical folders.

## Immich staging/import

- Never write files directly into Immich's managed upload mount (`/mnt/media/immich/data` / `/usr/src/app/upload`). Immich owns that layout.
- A separate NAS staging tree such as `/export/nas/immich/imports/<dated-import>` is an uploader source only, not a managed library.
- Check live health and CLI authentication first: `docker ps --filter name=immich` plus `IMMICH_CONFIG_DIR=... immich server-info`. Do not print API-key contents.
- The Immich CLI hashes locally by default and Immich performs server-side content-hash dedupe. Use `immich upload --dry-run --recursive --json-output <stage>` before actual upload; inspect `newFiles`, `duplicates`, and `newAssets`.
- For a cross-subvolume source→staging **move**, copy/reflink first, SHA-256 verify every staged file, write a move manifest, then remove only verified source media files. Limit to supported photo/video extensions; retain `.nomedia`, databases, logs and unrelated phone/app data in the recovery tree.
- Do not use `--delete` or `--delete-duplicates` in the first import run. Upload first, verify the resulting assets/albums and staged manifest, then seek explicit approval for staging cleanup.

## Verification/reporting

Report separately:

1. physical content sharing/dedupe status;
2. directory-level organisational cleanup still outstanding;
3. exact sources promoted, skipped, or blocked;
4. Immich dry-run duplicate/new counts and whether an actual upload has occurred.

Never present a physically reflinked recovery archive as semantically merged or ready for remote backup without the source-manifest decision.