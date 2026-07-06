# RX 6600 XT LACT Notes

Hardware:

- GPU: AMD Radeon RX 6600 XT
- PCI ID: `1002:73FF-1458:2337-0000:12:00.0`
- Board: Gigabyte
- Driver: `amdgpu`
- ASIC: Navi 23 / Dimgrey Cavefish
- VRAM: 8176 MiB GDDR6, 128-bit
- Resizable BAR: enabled
- PCIe: Gen 3 x8

Configured boot-time GPU profile:

- Service: `gpu-performance-oc.service`
- Installed unit path: `/etc/systemd/system/gpu-performance-oc.service`
- Installed script path: `/usr/local/sbin/apply-gpu-profile`
- Dotfiles copy: `pc/.config/dotfiles/pc/gpu/apply-gpu-profile.sh`
- Intended power cap: `162000000` uW (`162W`, effectively the remembered `163W` class)
- Intended DPM state: `high`
- Intended voltage offset: `vo 20`
- Commit command: `echo c > pp_od_clk_voltage`
- Frequency tuning: not configured yet

The actual apply script is:

```bash
echo high > "$gpu/power_dpm_force_performance_level"
echo 162000000 > "$hwmon/power1_cap"
echo "vo 20" > "$gpu/pp_od_clk_voltage"
echo c > "$gpu/pp_od_clk_voltage"
```

Failure behavior:

- If the RX 6600 XT is not found, the service logs a skip and exits successfully.
- If `pp_od_clk_voltage` is missing, the service logs that overdrive is unavailable and exits successfully.
- If `power1_cap` is missing, the service logs a skip and exits successfully.
- If the requested `162000000` uW is higher than the current exposed `power1_cap_max`, the service fails visibly instead of silently pretending the profile applied.
- If any kernel write fails while applying the profile, the service fails visibly.

This means a normal boot should not be blocked by missing overdrive support, but a bad/partial OC application should show as a failed `gpu-performance-oc.service`.

Current runtime state seen on 2026-07-01:

- `lactd.service`: enabled and active
- Current profile: `Default`
- `gpu-performance-oc.service`: enabled, ran successfully at boot
- Reported power limit: `135W`
- Reported configurable range: `126W` to `135W`
- Intended configured target: `162W` / `vo 20`

Important:

- The dotfiles should not put these values on Waybar.
- LACT should own overclock, overvolt, fan, and power-limit application.
- The dotfiles should only keep notes/scripts around the PC profile.

Why the runtime currently shows only `135W`:

- The running kernel command line does not include an amdgpu overdrive feature mask.
- Current `/proc/cmdline` has no `amdgpu.ppfeaturemask=...`.
- `pp_od_clk_voltage` was not exposed during inspection.
- The boot service exits successfully without applying anything if `pp_od_clk_voltage` never appears.
- From the live driver/LACT point of view, `135W` is currently the maximum configurable power cap.

Likely next step to restore the `162W` / `vo 20` profile:

```text
amdgpu.ppfeaturemask=0xffffffff
```

This needs to be added to the bootloader kernel command line, then rebooted. On this machine, the active bootloader is Limine and the current kernel command line appears to come from `/etc/default/limine`.

Helper saved in dotfiles:

```bash
sudo ~/.config/dotfiles/pc/gpu/restore-amdgpu-overdrive.sh
```

The helper does three permanent things:

1. Adds `amdgpu.ppfeaturemask=0xffffffff` to `/etc/default/limine`.
2. Runs `limine-mkinitcpio`.
3. Installs/enables the `gpu-performance-oc.service` and matching `/usr/local/sbin/apply-gpu-profile`.

Manual equivalent:

1. Add `amdgpu.ppfeaturemask=0xffffffff` inside `/etc/default/limine` on the `KERNEL_CMDLINE[default]+=` line.
2. Run `sudo limine-mkinitcpio`.
3. Reboot.
4. Check that `pp_od_clk_voltage` exists.
5. Restart `gpu-performance-oc.service` or reboot again.

Expected after restore:

```bash
cat /sys/class/drm/card1/device/hwmon/hwmon*/power1_cap
# 162000000
```

Rollback if it fails:

1. In the Limine boot menu, edit the boot entry and remove `amdgpu.ppfeaturemask=0xffffffff`, or boot another kernel/snapshot.
2. Remove `amdgpu.ppfeaturemask=0xffffffff` from `/etc/default/limine`.
3. Run `sudo limine-mkinitcpio`.
4. Disable the profile if needed: `sudo systemctl disable gpu-performance-oc.service`.

Useful commands:

```bash
cat /proc/cmdline
systemctl status gpu-performance-oc.service
lact cli info
lact cli stats
lact cli power-limit get
lact cli profile get
systemctl status lactd
```
