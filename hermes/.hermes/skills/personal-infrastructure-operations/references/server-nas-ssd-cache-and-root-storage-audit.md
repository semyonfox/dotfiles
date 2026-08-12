# Server/NAS SSD cache and root-storage audit

Use when evaluating whether Semyon's server NVMe or NAS OS NVMe should cache NAS-backed workloads, or when auditing their non-media/root disks.

## Decision model

- Treat the server NVMe as a **bounded working tier**, not a general NAS mirror: transcodes, incomplete downloads, unpack/repair/import staging, regenerated thumbnails/previews, app/build caches, indexes, and appropriate database runtime data.
- Keep durable originals, completed media, documents, and backups on the NAS. A server-local staging file is not complete until the NAS import/copy has finished and been verified.
- Do not create a deliberate RAM disk. Linux page cache is already opportunistic; laptop battery can improve orderly shutdown behaviour but is not durability against a crash or abrupt power loss.
- Devices other than the server should write durable data directly to the NAS. Routing them through the server adds a hop and does not make use of the server's SSD cache.
- A NAS SSD cache is lower priority when the server-to-NAS link is the bottleneck. Avoid broad write-back caching on the NAS OS SSD; it complicates recovery and can transiently make fresh data SSD-only.

## Benchmark workflow: distinguish disks from transport

Run bounded temporary-file tests and remove test files afterward. Measure, in this order:

1. Server↔NAS latency and raw bandwidth with temporary `iperf3 -s -1` on the NAS, in both directions.
2. Server NVMe direct sequential write/read.
3. NAS-local Btrfs/HDD direct sequential write/read using a temporary file on `/mnt/storage/users/semyon/`.
4. Same path via the server's NFS mount using direct I/O, plus an SSH streamed-file transfer as a cross-check when NFS is unexpectedly slower than raw `iperf3`.
5. Record the actual egress interface. The server may route NAS traffic over `wlp59s0` Wi-Fi even when Docker bridges report nominal 10G links.

Use 16 MiB blocks and remember `count` multiplies the size: `bs=16M count=32` is 512 MiB, while `count=512` is 8 GiB. Prefer `oflag=direct`, `iflag=direct`, and `conv=fdatasync` to avoid reporting RAM cache as disk/network throughput.

## Root-disk audits and Docker cleanup

- Audit only the intended filesystem with `du -x`; do not traverse `/mnt/media` or NAS Btrfs data during an OS-SSD audit.
- Compare `df` against `du`. A large gap on the server can be Docker overlay/image data that an unprivileged `du` cannot enumerate, plus ext4 reserved blocks; use `docker system df` to account for it. Check deleted open files separately before assuming the space is reclaimable.
- `docker system prune -af --volumes` removes unused images, stopped containers, build cache, networks, and anonymous dangling volumes without affecting running containers. Verify `docker ps` and `docker system df` afterward.
- Docker may leave **named** dangling volumes even with `--volumes`. Do not force-remove those merely because they are unused: names such as old PostgreSQL, Portainer, or SpiderFoot volumes can contain recovery data. Review them individually. A clearly disposable named cache volume may be removed explicitly.

## Moving a local NAS-user directory onto Btrfs HDD storage

For a large directory accidentally stored under NAS `/home` on the OS NVMe:

1. Check the intended Btrfs destination is absent and confirm no active application uses the directory.
2. Copy with `rsync -aHAX --numeric-ids SRC/ DST/`.
3. Verify with `rsync -aHAXnc --delete --itemize-changes SRC/ DST/`; require zero change lines.
4. Remove the validated source and replace it with an absolute symlink to the Btrfs path to preserve existing local references.
5. Verify the symlink resolves to the destination (`test SRC -ef DST`) and compare `df` on both filesystems.

This was used successfully for `/home/semyon/obsidian` → `/mnt/storage/users/semyon/obsidian`.
