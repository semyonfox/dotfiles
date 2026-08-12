---
name: linux-desktop-typography
description: "Use when diagnosing Linux app and browser font rendering."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux]

metadata:
  harness: [hermes]
---

# Linux Desktop Typography

## Use when

Use for Linux desktop/browser font selection, rendering mismatches, Windows-parity font policies, Fontconfig substitutions, GTK font settings, and unexpected monospace/typewriter UI rendering.

## Acceptance standard

Configuration output is evidence, not acceptance. A font fix is complete only when the affected application has been restarted and the user-visible UI is visually confirmed with a screenshot or direct user confirmation. Never claim success early.

## Investigation flow

1. Identify the precise affected surface: webpage CSS, browser content preference, native browser chrome, GTK/Qt app UI, compositor overlay, or terminal/code UI.
2. Capture the live screen before changing anything. Do not infer the face solely from appearance or `fc-match`.
3. Record application/version, OS, Fontconfig version, and generic resolution for `system-ui`, `ui-sans-serif`, `sans-serif`, `serif`, `monospace`, and `ui-monospace`.
4. Inspect relevant layers in parallel: Fontconfig rules, GTK settings/GSettings, application profile preferences, launcher/environment, extensions or injected styles, and upstream issue trackers.
5. Search upstream for the exact application + platform + visual symptom before trying broad substitutions. Package/version regressions can make otherwise valid preferences ineffective.
6. Scope each change to the smallest responsible layer. Fully close Chromium-family apps before modifying their profile JSON; write atomically; rebuild caches; restart; visually verify.
7. Keep rollback simple. Do not globally force a proportional face into a `monospace` request—code rendering relies on fixed metrics.

## Font policy guidance

Choose families by role rather than picking one face for every surface:

- UI at small sizes: prefer a screen-optimised sans with open forms and a stable weight ladder.
- Long reading: use a readable serif or sans with suitable line-height and measure.
- Code: use a genuine monospaced family.
- International text: retain a broad-script fallback such as Noto.

For a user seeking Windows visual parity on Linux, Segoe UI can be the UI/sans primary when legitimately present locally; retain Noto Sans/Noto Serif for broad-script and serif fallback. Account for licensing: do not redistribute Windows fonts as part of a public package.

## System package regressions

If upstream evidence establishes a Fontconfig regression, present the exact package/version and supported package-manager rollback option. A downgrade requires explicit approval because it is system-wide. Verify package signature/dependencies before requesting local authentication. State that normal system updates may reintroduce the version; do not add a permanent pin without explicit discussion of security/maintenance trade-offs.

## References

- `references/linux-browser-fontconfig-regressions.md` — verified Helium/Fontconfig case, research links, and a repeatable evidence checklist.
