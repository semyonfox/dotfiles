---
name: linux-font-configuration
description: "Use when use for Linux desktop/browser font mismatch diagnosis."
version: 1.0.0
created_by: agent

metadata:
  harness: [hermes]
---

# Linux Font Configuration

Use when a Linux desktop application or browser visibly renders an unexpected font, especially after a Windows-font migration or fontconfig change. Treat visible rendering—not a successful font lookup—as the completion criterion.

## Workflow

1. Capture the offending UI region before changing anything. Identify whether it is webpage content, browser chrome, an extension, a native browser feature, or desktop UI.
2. Inventory the active process, launcher arguments, profile path, and user/system font sources. For Chromium-family browsers, inspect the active profile's `webkit.webprefs.fonts` only while the browser is closed.
3. Inspect font-selection layers separately:
   - user Fontconfig (`~/.config/fontconfig`, `~/.fonts.conf`) and generic-family matches;
   - GTK settings and GSettings font values;
   - Qt settings where relevant;
   - desktop/compositor configs and browser extensions/styles.
4. Make one scoped change at a time. Fully stop the browser before profile edits; restart it only after the file is valid.
5. Verify two ways: query the relevant resolved family and capture a fresh live screenshot. Do not report success from `fc-match` alone.

## Pitfalls

- Copying legacy Windows `.fon` bitmap files can introduce a family named `System` and change generic/system font fallback. Keep legacy bitmap fonts outside active Fontconfig directories unless a named application explicitly requires them.
- Browser-native UI (including vertical-tab strips) may ignore webpage defaults and `webkit.webprefs.fonts`. If it remains unchanged after verified profile and Fontconfig changes, state that boundary clearly rather than repeatedly claiming a fix.
- A generic `monospace` request is intentionally constrained to fixed-width faces; attempting to substitute a proportional UI face via ordinary Fontconfig preference rules is not a validated browser-UI fix.
- Do not make global monospace changes merely to affect one browser region; preserve terminal/editor/launcher typography unless the user explicitly requests a system-wide change.

## Reporting

Lead with the visible result and name the layer that was actually verified. When the cause is unresolved, say so directly, list the already-excluded layers concisely, and avoid presenting experiments as working remedies.
