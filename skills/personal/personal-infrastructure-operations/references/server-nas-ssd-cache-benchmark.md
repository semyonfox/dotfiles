# Server ↔ NAS cache / throughput benchmark

## When to use

Use before proposing SSD caching, NFS tuning, or storage moves for services mounted from `/mnt/media`.

## Safe bounded benchmark procedure

1. **Confirm the actual network route, not just assumed Ethernet.**
   - `ip route get <nas-ip>` identifies the real interface.
   - For Wi-Fi, inspect `iw dev <interface> link`.
   - Check loss and jitter with a bounded ping sample.
2. **Measure raw link capacity independently of NFS.** Run short, single-flow `iperf3` tests in both directions, starting a one-shot temporary server on the NAS over SSH. This isolates network from disk/NFS.
3. **Measure NAS-local sequential disk speed.** Create a uniquely named bounded test file on the NAS storage filesystem with `dd` and `oflag=direct`, read it back with `iflag=direct`, then remove it in a cleanup trap.
4. **Measure the identical test through the NFS mount.** Use direct I/O to avoid reporting Linux page cache as NAS speed. Remove the test file even if a later command fails.
5. **Optionally read the NAS test file through SSH.** This gives a useful non-NFS transport comparison. Time the client-side command and calculate MiB/s from the known test size.
6. Do not parallelise disk and network tests: they contend and invalidate the result. Keep files bounded (normally 512 MiB) and state that tests perform temporary writes.

## Interpretation

- If NAS-local disk speed is much higher than NFS throughput, the bottleneck is transport and/or NFS, not the hard drives.
- If raw `iperf3` significantly exceeds NFS (particularly in just one direction), investigate NFS client/server behaviour and try a **temporary** alternate mount using `nconnect` before changing persistent mount configuration.
- Linux already has RAM page cache for repeated NFS reads. Prefer an SSD **working tier** (transcodes, incomplete downloads/unpacking, databases, Docker/thumbnail/generated caches) over blanket persistent NFS caching.
- Test hardwired LAN before adding complex cache layers when the server's route is Wi-Fi.

## Concrete July 2026 baseline

Server `10.0.0.5` reached NAS `10.0.0.6` using `wlp59s0` (5 GHz Wi-Fi), despite an assumed LAN path. The Wi-Fi link negotiated 650–867 Mbit/s with strong signal, but throughput was asymmetric:

| Test | Result |
|---|---:|
| server → NAS iperf3 | 231 Mbit/s |
| NAS → server iperf3 | 529 Mbit/s |
| NAS-local Btrfs/HDD direct write/read | 111 / 184 MB/s |
| NFS direct write/read | 20.5 / 28.9 MB/s |
| NAS → server SSH direct file transfer | 50.0 MiB/s |
| server NVMe direct write/read (8 GiB test) | 454 / 3,091 MiB/s |

The result justified NVMe placement for high-churn working data, but not a whole-NAS persistent cache. It also showed an NFS throughput gap worth testing with a temporary multi-connection mount after wiring is ruled out.
