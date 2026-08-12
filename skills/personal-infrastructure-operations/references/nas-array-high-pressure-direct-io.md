# NAS array high-pressure direct-I/O test

Use this when Semyon explicitly asks for a **full-speed / high-pressure** test of the NAS HDD array and wants resource attribution. This is intentionally more invasive than a normal bounded benchmark, but it is still non-destructive: all test data must be temporary and removed.

## Preconditions

1. Confirm the target is the NAS data filesystem, not the OS NVMe or an NFS client mount.
2. Check free capacity, current load, active high-CPU/I/O processes, and baseline CPU/memory/I/O PSI. Do not silently stack the test on a backup, scrub, snapshot, or recovery job.
3. State the logical and RAID-amplified write volume. On RAID10, 8 GiB logical write consumes roughly 16 GiB of physical write traffic.
4. Do **not** run a network test concurrently; that corrupts both storage and network conclusions.

## Procedure

- Create four uniquely named files directly on the NAS data filesystem.
- Use four concurrent `dd` jobs with `oflag=direct,conv=fdatasync`; 2 GiB per file (8 GiB logical) is a useful one-minute stress size for this fleet.
- Time the aggregate write, then read all four files concurrently with `iflag=direct`, again recording aggregate throughput.
- In parallel, sample for slightly longer than the workload (for example 80 seconds):
  - CPU utilisation from two `/proc/stat` snapshots;
  - `MemAvailable` and swap used from `/proc/meminfo`;
  - CPU, memory, and I/O PSI from `/proc/pressure/*`;
  - per-HDD sectors read/written and `io_ms` from `/proc/diskstats` for `sda`–`sdd`.
- Interpret per-disk busy percentages over the whole sample as averages; if the sample includes idle/setup/cleanup time, do not call them peak utilisation.
- Remove every temporary file with a trap and verify both the target directory has no test files and no test listener/process remains.

## Interpretation

- `CPU full` PSI of zero and stable `MemAvailable`/swap prove the CPU/RAM did not limit the workload even if average CPU is non-trivial.
- Material `I/O full` PSI means runnable work was blocked on disk: that is expected under an intentional HDD-array saturation test and attributes pressure to storage rather than CPU/RAM.
- RAID10 concurrent reads can be materially faster than writes because reads are distributed over stripes/replicas while writes require duplicate copies.
- Compare long-enough aggregate reads—not a tiny single-file result—against network payload ceilings before recommending faster Ethernet. In this fleet, the 4× IronWolf RAID10 sustained 254 MiB/s write and 399 MiB/s read in an 8 GiB logical / four-way direct-I/O test; it can justify 5GbE for wired clients, while 10GbE remains disproportionate for four HDDs alone.
