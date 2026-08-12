# Resolve project libraries and NAS media topology

Use when Semyon wants to move between devices, keep a Resolve library on NAS, configure collaboration, or diagnose slow conform/export workflows.

## Separate three layers

```text
Project library database  ≠  media originals  ≠  proxies/cache
```

Recommended default for a single active workstation:

```text
PC local NVMe:
- Resolve Disk Database / local project library
- proxies
- optimized media
- render cache

NAS:
- camera / OBS originals
- finished exports
- versioned project-library backups
```

Do not put Resolve's active Disk Database folder on SFTP/GVFS, SMB, or NFS merely to make it "remote". A Disk Database consists of interdependent local files such as `User.db` and `Project.db`; interrupted network filesystems can break locking, rename, or commit expectations.

## Real remote library versus a mounted folder

A mounted Disk Database is not a Resolve remote project library.

For real shared concurrent work, use one of:

1. **Blackmagic Cloud** for occasional remote collaboration. Project metadata is shared; collaborators still need the media or proxies separately.
2. **Dedicated PostgreSQL Resolve library** for frequent multi-workstation collaboration. Keep it separate from unrelated application databases and restrict access to LAN/VPN/Tailscale, never public PostgreSQL.

Blackmagic's official Project Server app has no Linux server edition. A Linux deployment therefore needs carefully-managed dedicated PostgreSQL or a maintained third-party implementation. Do not recommend building this for a solo creator before validating that collaboration is recurring.

## Legacy library migration

When a legacy Disk Database exists on NAS:

1. Inventory its projects and compare timestamps with the local library.
2. Do not replace or merge live databases in place.
3. Back up the current local library first.
4. Copy/restore the NAS library locally while Resolve is closed, or import selected projects into the target library.
5. Open representative projects and relink media before declaring migration complete.
6. Preserve the NAS source as a recovery copy until validation finishes.

## Resolve proxy workflow under constrained local storage

The correct workflow is not to copy every original back to the PC before final render:

1. Ingest/record locally.
2. Generate proxies, optimized media, and cache on local NVMe.
3. Archive originals to NAS.
4. Relink the project originals to a stable NAS path.
5. Edit with proxies locally.
6. At deliver time, switch to camera originals and render directly from NAS.

For active editing, use NFS/SMB over a fast wired link, not a GVFS SFTP convenience mount. An SFTP mount can be useful for browsing/transferring but is not the high-throughput media path.

## Direct PC-to-NAS editing link

A dedicated 2.5GbE PC↔NAS cable should be a separate subnet with no gateway, for example:

```text
NAS: 192.168.250.1/30
PC:  192.168.250.2/30
```

Keep ordinary LAN/internet routes on the existing interface. Mount the NAS NFS export using the dedicated NAS address and a stable path such as `/mnt/nas-media` so Resolve relinks do not drift.

Before asserting 2.5GbE is working:

1. Check both NICs report carrier/link up.
2. Check negotiated speed on both endpoints.
3. Run a bidirectional memory-only TCP/iperf test before disk-copy testing.
4. Measure NAS disk throughput separately only after the network link is known good.

A workstation can report a 1GbE negotiated link yet still achieve ~30Mb/s through a powerline, poor uplink, or intermediary path. Test sustained throughput rather than trusting link speed.

## Portable-proxy, multi-device editing

For a creator who moves between a primary PC and laptop with a USB SSD of proxies:

```text
Dedicated PostgreSQL Project Library: shared edits, timelines, grades, metadata
USB proxy SSD: portable proxy media, consistently labelled/mounted on both devices
NAS: originals, exports, database backups
Each editor: local cache and optimized media (disposable)
```

A dedicated network library is justified for this workflow even when there is only one person editing at a time: it removes export/import handoffs between the PC and laptop. Give the USB proxy volume a stable label and configure the same logical media path on both systems to avoid relinking. If editing offline without connectivity, use an explicit `.drp` project handoff and avoid parallel offline edits of the same project.

## Collaboration and least-privilege design

Resolve access control is **library-scoped**, not project-scoped. Treat a Project Library as the trust boundary.

- Keep personal/archive projects in a private library, for example `foxscope-private`.
- For a friend working on one project, create a separate library such as `collab-subnautica-2`; import/duplicate only that project into it.
- Create a distinct member account and assign it only to the collaboration library as a Collaborator, never share the default/shared database credentials.
- Do not assume a Collaborator role is granular timeline or project RBAC. Anyone admitted to a library should be treated as able to access the projects within it; keep that library purpose-limited and take a backup before granting access.
- Restrict the PostgreSQL service to LAN plus authenticated VPN/Tailscale clients. Never port-forward it publicly.
- Grant collaborators only a project-specific proxy/media share or deliver them a proxy pack. Never grant the entire NAS or personal media archive.
- At the end of a collaboration, remove the member, revoke VPN/device access, remove the project media share, and retain the server backup.

Resolve 20's Project Server member management supports per-member Administrator/Collaborator roles and assignment of members to specific Project Libraries. On a Linux self-hosted setup, test the chosen compatible PostgreSQL/Project-Server implementation's member flow on a disposable library before migration. Do not attach Resolve to an unrelated application PostgreSQL instance or assume an arbitrary current PostgreSQL image is Resolve-compatible.

## Known legacy locations to verify live

```text
Linux local library:
~/.local/share/DaVinciResolve/Resolve Project Library/

Legacy NAS library candidate:
~/NAS/device_dumps/windows_pc/resolve/Resolve Project Library/

NAS media shortcuts on PC:
~/NAS
~/NAS-Videos
~/NAS-Editing
```
