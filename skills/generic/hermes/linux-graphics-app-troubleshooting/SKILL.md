---
name: linux-graphics-app-troubleshooting
description: "Use when debugging Linux GPU-accelerated creative apps."
version: 1.0.0
created_by: agent

metadata:
  harness: [hermes]
---

# Linux graphics-app troubleshooting

Use for a production creative application on Linux that launches imperfectly, has GPU/compute/audio/media rough edges, or is being compared against a community installation guide. This applies especially to video editors, compositors, CAD, 3D, and colour tools.

## Outcome

Improve a working application without accidentally converting it into a broken reinstall. Diagnose first, separate unrelated failures, and propose one reversible test at a time.

## Communication: one rung at a time

When Semyon asks for help on a complicated desktop/system problem:

1. Start with the plain-English status: **working**, **partly working**, or **broken**.
2. Explain one concept before proposing a change. Do not dump all findings, caveats, and phases at once.
3. State the single next action and what it cannot affect.
4. Keep later findings in a short "later" bucket until the current step is understood.
5. Use technical detail only after the user asks why, or in a clearly separate appendix.

A long evidence dump can be correct but still unhelpful. Prefer: "one physical GPU, two software compute routes" over a package-level explanation as the first answer.

## Safety principles

- Treat a paid/proprietary application, its licence, project database, project media, LUTs, and existing wrappers as preservation boundaries.
- Never replace a launcher until its content and the actual desktop entry used by the user are inspected.
- Never run an installer, package downgrade, global OpenCL change, service restart, database action, or config wipe merely because a guide recommends it.
- Back up/export project state before a change that could alter an application database or user configuration.
- Do not use a headless SSH attempt to launch a GUI app or an unsupported `--version` flag as evidence that the normal desktop launch is broken.
- Prefer an application-specific environment wrapper over global graphics-stack package changes.

## Read-only discovery sequence

### 1. Establish the real launch path

Inspect, without mutation:

- the system and user `.desktop` entries;
- the command they execute, `Path=`, `TryExec=`, and MIME associations;
- custom wrappers in `~/.local/bin`, scripts, aliases, and shell configs;
- environment variables such as `LD_PRELOAD`, `HSA_OVERRIDE_GFX_VERSION`, `ROCR_VISIBLE_DEVICES`, `OCL_ICD_VENDORS`, `DRI_PRIME`, and Mesa Vulkan selectors.

Read every wrapper before proposing edits. A custom wrapper may be preserving an important codec, input-method, library, or compatibility workaround. Extend that wrapper rather than introducing competing launch paths.

### 2. Inventory graphics layers separately

Do not collapse all "GPU drivers" into one thing. Capture:

| Layer | What to verify |
|---|---|
| Kernel | GPU PCI device, driver in use, `/dev/dri`, user render/video groups |
| Display/rendering | Desktop-session `glxinfo -B`, `vulkaninfo --summary`, actual OpenGL and Vulkan renderer |
| Compute | `clinfo -l`, installed OpenCL ICD files and their owning packages |
| App | Its log: detected GPUs, selected compute API, selected devices, context failures |

A desktop/session probe must use the graphical user's session environment where necessary; a bare SSH environment can lack the Wayland/X11 variables needed for valid OpenGL results.

### 3. Classify each log finding

Put each finding in exactly one bucket:

- **Blocking GPU problem:** context creation failure, reset, reproducible crash on a compute page, intended GPU absent.
- **Competing-provider ambiguity:** multiple OpenCL/Vulkan devices or implementations represent the same physical card.
- **Project migration issue:** missing files at old paths, offline media, missing LUTs/fonts/plugins.
- **Application feature warning:** e.g. unavailable hardware encoder, no optional control-surface/DeckLink device.
- **Host capacity issue:** disk/cache exhaustion, RAM/VRAM pressure.
- **Shutdown-only issue:** assertion after a clean save/exit; investigate separately from launch stability.

Do not prescribe GPU surgery for a project relink problem or an optional-codec warning.

## Multiple compute providers on one AMD GPU

Mesa and ROCm can both expose OpenCL implementations for the same AMD card:

- Mesa is normally indispensable for Linux desktop rendering and AMD gaming (OpenGL/Vulkan/RADV).
- ROCm is commonly used for AMD compute workloads and some professional applications.
- Mesa's Rusticl/OpenCL capability is not evidence that Mesa is unwanted or that gaming is misconfigured.

If an application logs two instances of one physical card and auto-selects both, form a hypothesis that provider ambiguity contributes to the rough edge. The low-risk investigation is an **application-only** launch test that restricts the app to the intended compute ICD/provider while leaving Mesa, gaming, and the system untouched.

This is a hypothesis, not an automatic fix. Before proposing it:

1. Identify every ICD and its package owner.
2. Verify the app currently launches and has a known good baseline.
3. Preserve all existing wrapper environment variables, especially `LD_PRELOAD`.
4. Make the test launcher separate or make a timestamped backup of the existing user launcher.
5. Define success before running: one intended compute device in the app log, successful launch, required GPU page/function works, no regression in import/export/audio.
6. Define rollback: return to the existing launcher; do not uninstall Mesa/Rusticl or downgrade packages as part of this test.

## Gaming and OBS workload contention

For a game that has poor FPS while OBS reports rendering or encoder overload, inspect the target machine directly before attributing it to VRAM, CPU encoding, or a broken GPU. Collect GPU busy/VRAM/clocks/power, process attribution, the game’s effective resolution/upscaler settings, and OBS’s active profile plus latest log.

Start by distinguishing **game 3D saturation**, **OBS rendering lag**, and **OBS encoding lag**. A hardware VA-API/AMF encoder is usually preferable to CPU/x264, but it is not wholly isolated: capture/compositing, VRAM, bandwidth and video-encode capacity remain shared. If the game already consumes almost all GPU time, first reduce OBS output burden (actual output resolution/FPS and unneeded simultaneous outputs), then cap game FPS to leave headroom. Do not change encoder types as a reflex.

OBS logs are especially useful because they state the true output resolution/FPS, every started encoder/output, and end-of-session rendering-lag/encoding-lag counters. Review extra Source Record filters: duplicated or unnecessary source recordings can create extra concurrent hardware encoders. Preserve the profile and test one reversible change at a time.

For exact SSH probes, log markers, and remediation order, see [references/amd-obs-game-encoder-diagnosis.md](references/amd-obs-game-encoder-diagnosis.md).

## Community-guide review

Treat guides as hypotheses, not authority.

1. Check hardware scope: GPU generation, single-GPU desktop vs hybrid laptop, application edition/version, distribution and package versions.
2. Separate guide components:
   - installation/extraction/library compatibility;
   - compute stack version/pinning;
   - hybrid GPU selection variables;
   - audio plumbing;
   - compositor/window rules.
3. Mark each as **directly applicable**, **possibly applicable**, or **not applicable**.
4. Cross-check strong claims against upstream issue trackers, distribution documentation, and present host evidence.
5. If the guide demands a global package downgrade but the app is currently functional, do not recommend it as phase one. Require a reproducible symptom and a rollback plan.

## Phased remediation template

### Phase 0 — preserve and baseline

- Back up/export the project database and record current launch path.
- Capture package versions, GPU/app log excerpts, disk headroom, and a minimal behaviour checklist.
- Do not clear user configuration merely because it contains old errors.

### Phase 1 — one reversible application-scoped test

- Change only the wrapper/launch environment or create an explicitly named test launcher.
- Preserve existing compatibility shims.
- Test the exact workflow the user reports, then compare logs against the baseline.
- Stop and roll back on a regression.

### Phase 2 — fix independent project assets

- Relink offline media through the application’s supported workflow.
- Restore or deliberately replace missing LUT/font/plugin assets.
- Do not solve path migration by mass-changing project files outside the application without a verified backup.

### Phase 3 — host changes only if evidence requires them

- Address cache/headroom when disk is materially constrained.
- Add audio plumbing only after confirming a host audio/output issue distinct from offline project audio.
- Consider package pinning/downgrade only after reproducible GPU failure, source support, package transaction rollback, and a backup.

## Report format

Use this order:

1. **One-sentence status** — e.g. "The app works; we are reducing ambiguity, not rescuing it."
2. **One current issue** — explain only the next item in plain English.
3. **Why it exists** — short distinction between system components.
4. **One safe next step** — expected result, what is untouched, rollback.
5. **Later, not now** — max three bullets.
6. Technical evidence only on request or below a divider.

## Verification checklist

- [ ] Actual user launcher and desktop entry identified
- [ ] Existing custom wrapper preserved
- [ ] Graphics, compute, and app-log evidence compared separately
- [ ] Findings classified rather than treated as one GPU failure
- [ ] No global change recommended without a reproducible need and rollback
- [ ] Next test is singular, scoped, and reversible
- [ ] User can understand the immediate next step without reading an incident report
