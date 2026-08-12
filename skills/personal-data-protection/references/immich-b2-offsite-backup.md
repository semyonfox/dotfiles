# Immich NAS → Backblaze B2 offsite baseline

Use for Semyon's mission-critical Immich recovery path. Re-check provider pricing before quoting it; figures below were verified from official pages on 2026-07-20.

## Architecture

```text
Immich managed UPLOAD_LOCATION on NAS
  + current application-consistent PostgreSQL dump
  + deployment config (restricted permissions)
→ restic, client-side encrypted
→ Backblaze B2 account in EU Central (Amsterdam)
```

Keep it separate from the server→NAS mirror. NAS Btrfs snapshots/local copies are rollback and local recovery layers, **not** offsite protection.

## Immutable source boundaries

- The Immich server bind-mounts `/mnt/media/immich/data` as `UPLOAD_LOCATION`.
- Protect both `data/library` **and** `data/upload`, plus `data/backups` and an independently produced PostgreSQL dump.
- Exclude rebuildable `thumbs`, `encoded-video`, and cache directories only after checking the deployed Immich version/path layout.
- Never manually move `upload` into `library` or rearrange the managed tree. Immich database rows track file paths and the server does not reconstruct them by scanning a library directory.
- For human-readable date/user organisation, take an initial verified offsite snapshot first, then use Immich's Storage Template/job tooling—not filesystem moves. Back up before and after a large storage-template migration.
- Do not treat `imports/` as canonical offsite input until its import/recovery value has been reviewed.

## Current local recovery point pattern

Create a custom-format, application-consistent dump from the live container; validate it before publishing:

```bash
backup_root=/mnt/media/backups/immich/current
stamp=$(date -u +%Y%m%dT%H%M%SZ)
tmp="$backup_root/.staging-$stamp"; final="$backup_root/$stamp"
umask 077; mkdir -p "$tmp"
docker exec immich_postgres sh -c 'exec pg_dump -Fc -U "$POSTGRES_USER" "$POSTGRES_DB"' > "$tmp/immich-postgres.dump"
docker exec -i immich_postgres pg_restore --list < "$tmp/immich-postgres.dump" > "$tmp/immich-postgres.contents.txt"
install -m 600 /home/semyon/server-stacks/immich/stack.env "$tmp/stack.env"
install -m 600 /home/semyon/server-stacks/immich/stack.yaml "$tmp/stack.yaml"
(
  cd "$tmp"
  sha256sum immich-postgres.dump stack.env stack.yaml > SHA256SUMS
  sha256sum -c SHA256SUMS
)
chmod 700 "$tmp"; chmod 600 "$tmp"/*
mv "$tmp" "$final"
```

**Pitfall:** do not generate `SHA256SUMS` with absolute paths containing the staging directory and then rename the directory; it makes the manifest unusable. Generate it after publishing or from inside the final directory with relative filenames.

## Provider decision (verified 2026-07-20)

- Backblaze B2 pay-as-you-go: **$5/TB-month**. EU Central data resides in Amsterdam; Backblaze states storage pricing does not vary by region.
- Cloudflare R2 Standard: **$0.015/GB-month** ($15/TB-month); Infrequent Access: $0.01/GB-month plus retrieval charge. It is not cheaper for the active restic repository.
- Backblaze B2 Reserve: capacity commitment through resellers, starts at **20 TB** / 1–3 years, published effective rate about $6.50/TB-month. Not suitable for a 1–3 TB personal repository.
- Backblaze Personal Computer Backup: $9/month or $99/year for one Mac/Windows computer plus attached external drives, but **does not support NAS/network shares** and is not a replacement for B2/restic. It cannot protect this Linux server/NAS Immich source.

Choose ordinary B2 in EU Central for this workload. Create the bucket/account in that region, use a bucket-scoped restricted application key, and consider Object Lock availability during bucket creation. Do not put keys or repository passwords in chat, Git, logs, or command-line history. If a password was pasted into chat, replace it before production repository initialisation and save the new value in Vaultwarden.

## Completion criteria

1. B2 bucket/key and restic repository exist; secret material is in restrictive local files/Vaultwarden only.
2. First backup includes canonical managed media plus DB/config source set.
3. `restic check` succeeds.
4. Restore one database dump and one representative original to a disposable target; hash/parse both.
5. Scheduled backup, retention, stale-last-success, and failed-check alerts are in place.
6. Only then call Immich offsite-protected.
