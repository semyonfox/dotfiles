# Linux Gaming Ready Design

## Goal

Prepare this CachyOS Hyprland laptop for a reliable, high-performance Linux gaming setup focused on Steam and Epic games, while avoiding unnecessary launcher and Wine complexity.

## Current State

- OS: CachyOS
- Session: Wayland on Hyprland
- GPU: Intel Iris Xe (Tiger Lake)
- Installed gaming stack: Steam, Heroic, Lutris, Wine, winetricks, MangoHud, GameMode libraries, Gamescope, Vulkan tools, Intel Vulkan driver, Mesa, `umu-launcher`
- Current preference: willing to use newer or more experimental game runners if they improve compatibility or performance

## Recommended Architecture

Use a Proton-first setup with two main launchers:

- Steam for Steam library titles
- Heroic for Epic titles

Treat standalone Wine as a low-level compatibility dependency rather than the main user-facing runtime. Prefer Proton, Proton Experimental, Proton Hotfix, GE-Proton, and UMU-backed Proton runners before trying raw Wine prefixes.

Keep the system-wide graphics stack mostly unchanged because the current Mesa and Intel Vulkan setup is already current and healthy.

## Launcher Strategy

### Steam

- Enable Steam Play for supported and unsupported titles
- Use `Proton Experimental` as the default runtime
- Keep `Proton Hotfix` available as a fallback
- Install and keep the latest `GE-Proton` available for titles that behave better outside Valve's default Proton builds

### Heroic

- Keep Heroic as the main Epic launcher
- Prefer `UMU` with Proton or `GE-Proton` over ad hoc standalone Wine runners
- Use per-game runner overrides only when a title needs them

### Lutris

- Lutris is optional for this system
- It is not the primary recommendation for the current usage pattern because Epic plus Steam are already covered better by Heroic and Steam
- It can be kept as an escape hatch for unusual installers or future launcher needs, but it is not required for the target setup

## Performance and Session Strategy

Do not force a global gaming mode yet.

- Keep the default launch path simple while baseline performance is tested
- Keep tools like MangoHud and Gamescope available, but use them as opt-in troubleshooting or tuning tools
- Avoid committing to a permanent wrapper strategy until real game testing shows a need

Potential modes to evaluate later:

- Normal mode: direct Steam or Heroic launch with no wrapper
- Gamescope mode: used only for fullscreen, scaling, or frame pacing issues
- Performance mode: per-game MangoHud and GameMode toggles for heavier titles
- Battery-friendly mode: lower frame caps and fewer wrappers for light or portable play

## Package and Runtime Decisions

- Keep `steam`
- Keep `heroic-games-launcher-bin`
- Keep the current Mesa, Vulkan, and `lib32` graphics packages
- Keep `gamescope`, `mangohud`, `gamemode`, and `umu-launcher`
- Install or confirm availability of a current `GE-Proton` package or runner source
- Keep `wine` only as a compatibility dependency, not as the preferred manual workflow
- Remove or ignore `lutris` depending on whether future edge-case launchers matter enough to justify it

## Error Handling and Recovery

When a game fails:

1. retry with a different Proton build before touching raw Wine
2. check the game's known-good runner on ProtonDB or Heroic community reports
3. try a per-game Heroic or Steam override instead of changing global defaults
4. use Gamescope only if the failure looks display-session related
5. use Wine directly only as a last resort for titles that truly need it

This keeps troubleshooting narrow and avoids the common Linux gaming failure mode of changing too many layers at once.

## Verification Plan

After implementation, verify with:

- `vulkaninfo --summary` to confirm Vulkan remains healthy
- Steam launching a known Proton title
- Heroic launching a known Epic title
- one title tested with default launch behavior before enabling optional wrappers
- runner fallback validation by switching one known game between Proton Experimental and GE-Proton

## Non-Goals

- no forced global Gamescope wrapping
- no full standalone Wine-centric workflow
- no broad launcher sprawl for services the user does not currently use
- no premature performance-mode tuning before baseline tests exist
