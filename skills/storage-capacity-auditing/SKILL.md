---
name: storage-capacity-auditing
description: "Use when audit local disk usage, explain df-versus-du gaps, classify reclaimable/offload candidates, and publish safe visual storage maps."
version: 1.0.0
created_by: agent

metadata:
  harness: [hermes]
---

# Storage Capacity Auditing

Use when a user asks why a local disk is full, wants a complete space map, needs candidates for cleanup or NAS/offsite migration, or wants a visual artifact explaining storage usage.

## Goals

- Establish the physical-disk, partition, filesystem, and free-space facts.
- Explain apparent `df`/`du` mismatches without hand-waving.
- Separate live state from rebuildable caches and archival/offload candidates.
- Make no destructive move or deletion unless the user explicitly approves its exact scope.

## Read-only audit workflow

1. Identify capacity precisely:
   ```bash
   lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS,MODEL
   findmnt -no SOURCE,FSTYPE,OPTIONS /
   df -hT /
   ```
   State marketed decimal capacity separately from binary GiB and usable filesystem capacity.

2. Inventory visible usage, remaining on the root filesystem:
   ```bash
   du -xhd1 / 2>/dev/null | sort -h
   du -xhd1 "$HOME" 2>/dev/null | sort -h
   du -xsh /tmp /var/tmp 2>/dev/null
   docker system df
   docker ps -as --format 'table {{.Names}}\t{{.Size}}\t{{.Status}}'
   ```

3. Audit large home-directory content by role, not just size:
   - live databases, agent/T3/session state, app configuration, and running service binds: **retain locally** unless a migration is explicitly designed;
   - package/build caches and generated output: **rebuildable**;
   - dated backups, device staging, completed exports/transcriptions, and recovery archives: **NAS-offload review candidates**;
   - local model stores: retain locally for performance; identify unused models for deliberate removal instead of moving a live model path to NFS.

4. Account for invisible/root-owned usage. A normal user-level `du` can undercount root-owned Docker overlay data. Corroborate using `docker system df`, then inspect with an elevated read-only collector when available. Also inspect deleted-but-open files and ext4 reserved blocks.

5. Never add Docker logical totals directly to a `du /var` total: Docker uses shared layers and its logical inventory overlaps its on-disk tree. Explain categories and uncertainty rather than presenting a fake exact sum.

## Elevated read-only collection

Use `scripts/root-disk-map.sh` after an authenticated local sudo session. It collects root tree usage, Docker-root usage, Docker logical usage, deleted-open files, and ext4 reserved-block metadata.

- If sudo needs a password that the agent does not possess, do **not** ask for, transmit, or expose the password in chat.
- Provide the exact local command for the user to run and label the current map as non-root/partial coverage.
- Never claim a complete root accounting before the elevated collector is available.

## Dependency cache and lockfile workspace cleanup checklist

When `/home` is pressured by active development stacks, start with targeted dependency caches instead of broad deletes. Keep rebuildable caches and keep live project directories intact unless the user explicitly approves removals.

1. Measure known heavy caches first:

```bash
du -sh ~/.npm ~/.npm/_cacache ~/.npm/_npx ~/.cache ~/.local/share/pnpm ~/.cargo ~/.rustup 2>/dev/null

du -sh ~/go/pkg/mod 2>/dev/null || true
``` 

2. For Node/npm ecosystems (user asked for repeated refresh):
   - `npm cache clean --force` (non-destructive to lockfiles; re-downloads packages on next install)
   - `pnpm store prune` (prunes unused package metadata)
   - remove `node_modules` only in explicit project targets if deps are being fully reinstalled

3. For Rust/Cargo stacks:
   - run `cargo fetch`/`cargo update` in active projects to refresh only needed indexes/artifacts;
   - prefer `rustup toolchain list` + keep only required stable/default toolchain unless explicitly requested otherwise.

4. For Go/Python/other stacks:
   - clear temporary module/build caches only when the project explicitly tolerates re-download and rebuild (`go clean -modcache`, pip cache clean, etc.).

5. Run `df -h` and `du -xhd1 /home` after each phase; only report reclaimed space once all targets are complete and containerized workloads are excluded from scope if requested.

## Read-only source-scope audits on NAS/NFS

When the user asks for project/config/database-export include candidates, do not begin with a whole-tree recursive `du` or file walk on a remote NAS: it can time out and does not yield a usable allow-list. Instead:

1. Confirm the requested root's mount, filesystem, and capacity with `findmnt -T <root>` and `df -hT <root>`.
2. List immediate children and use non-content markers to shortlist explicit roots (for example `.git`, `package.json`, `docker-compose.yml`, `.config`, `.sql`, `.dump`, and named application-backup archives).
3. Measure each shortlisted root independently using `du -sh --apparent-size`; identify the result as apparent/logical size. If it times out, report that limitation rather than extrapolating.
4. For Git trees, collect origins with `git remote get-url origin` and use `git ls-files -z` for counts. Label those counts **Git-tracked files**, not full filesystem counts: generated, ignored, and untracked files are excluded.
5. For database candidates, inspect safe format/header metadata only (such as `file` and a small prefix) and distinguish logical SQL/custom dumps from live application database directories. Treat implausibly tiny archives as unvalidated until an explicitly requested integrity/content check.
6. For retention roots, record `latest` symlink targets and do not count symlink entries as independent payloads or blindly sum potentially duplicated retention tiers.
7. Do not expose secret values while classifying configuration. Trees containing `.env`, credentials, recovery codes, or stack environment files require a secret-review/encryption warning before recommendation.

Report an explicit path allow-list, observed apparent size plus the basis for each file count, evidence, classification, and exclusions. Keep broad device dumps, generic application-state trees, and live database directories outside a narrow project/config/export scope unless the user explicitly selects them.

## NAS-offload planning

Before moving data to a NAS:

1. Verify the mount and capacity (`findmnt`, `df -h <mount>`).
2. Identify exact archive roots; exclude live databases, active workspaces, Docker volumes, and service paths.
3. Copy, preserve timestamps, produce a SHA-256 manifest, verify destination hashes, then request/act on explicit approval for removal of the local source.
4. Keep a receipt outside the moved data tree. Do not use a blind move as the only copy.

A useful first pass is dated database backups and device/recovery staging, not a live state directory.

## Visual reports and Seol

When the user asks for a visual file tree or storage report, generate a static self-contained HTML artifact containing:

- physical disk → filesystem capacity and `df` usage;
- a readable file tree of major roots and their roles;
- Docker as a distinct root-owned/non-additive category;
- active temporary working directories;
- live/rebuildable/archive labels; and
- a NAS-offload shortlist with a safe copy-and-verify note.

For Seol publication:

1. Ensure the artifact is script-free and contains no secrets, tokens, or unnecessarily private filenames.
2. Publish with a bounded expiry.
3. Fetch the returned URL and verify an HTTP success plus the report's expected visible headings.
4. State that Seol is public temporary sharing and include its expiry in the handoff.

## Reporting

Lead with the disk's real capacity, current use/free space, and the largest categories. Clearly distinguish observed values from root-only unknowns. Recommend a staged offload or cleanup sequence; do not execute it until the user authorizes the named source paths.
