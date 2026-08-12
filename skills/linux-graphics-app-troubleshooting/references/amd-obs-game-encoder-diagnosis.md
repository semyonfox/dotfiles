# AMD game + OBS encoder diagnosis

Use this evidence pattern on a Linux gaming workstation when a game stutters or has poor FPS while OBS reports encoding overload.

## Read-only SSH probes

Run probes in the *target desktop user's session* where a compositor/environment query is needed; kernel/DRM and process probes work over ordinary SSH.

```bash
# AMD workload, clocks, power and VRAM
for p in /sys/class/drm/card*/device/{gpu_busy_percent,mem_info_vram_used,mem_info_vram_total,pp_dpm_sclk,pp_dpm_mclk,power_dpm_force_performance_level}; do
  [ -r "$p" ] && { echo "--- $p"; cat "$p"; }
done

# process attribution
ps -eo pid,ppid,user,comm,%cpu,%mem,etimes,args --sort=-%cpu

# OBS configuration and latest log (read only)
# ~/.config/obs-studio/basic/profiles/<profile>/basic.ini
# ~/.config/obs-studio/logs/<latest>.txt
```

## Interpretation

- High `gpu_busy_percent`, maximum graphics/memory clocks, and normal core/hotspot temperatures indicate saturation, not thermal throttling or a bad clock state.
- Hardware VA-API/AMF encoding uses a dedicated video-encode block, but it still needs VRAM, memory bandwidth and GPU time for compositing/copying. A game at 99% GPU can therefore cause OBS rendering or encoding lag.
- Do **not** recommend CPU/x264 as the first reaction. It can trade a video-engine bottleneck for game-thread contention. First lower the encoding workload and leave GPU headroom.
- `ps` can prove the game/OBS are active but cannot cleanly apportion AMD GPU-engine time by process on every driver/tool stack. Use OBS’s own end-of-session counters for the decisive attribution.

## OBS log checks

Inspect the latest log for:

- `output resolution` and FPS;
- one or more `FFmpeg VAAPI encoder` starts;
- separate `Source Record` outputs/filters;
- `Number of lagged frames due to rendering lag/stalls`;
- `skipped frames due to encoding lag`.

A common failure mode is a high-resolution canvas/output (for example native ultrawide) at 60 FPS, *plus* a primary recording and extra Source Record encoders. Each concurrent VA-API output contributes real encoder pressure. Multiple simultaneous starts for the same source-record filename deserve immediate review for duplicate filters.

## Remediation order

1. Preserve the current OBS profile. Do not change encoder/quality globally before identifying every active output.
2. Match the recording output to the delivery requirement (often 1920x1080), while retaining a larger base canvas if needed.
3. Disable duplicate or unnecessary Source Record filters; keep only intentional isolated recordings.
4. Cap game FPS enough to leave GPU headroom for OBS (test 30/60 before raising it).
5. Enable the game's supported upscaler or lower GPU-heavy settings; check the game config rather than assuming “1080p” means the actual render/output load.
6. Make one change, record briefly, then read OBS’s rendering-lag and encoding-lag counters again.

Keep the explanations short and give the immediate bottleneck first: “OBS is encoding N outputs at X while the game owns ~100% GPU; reduce outputs/resolution before changing encoder type.”
