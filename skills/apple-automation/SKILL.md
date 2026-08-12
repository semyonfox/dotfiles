---
name: apple-automation
description: "Use when class-level macOS and Apple-device automation: screen-driven computer use, AppleScript, screenshots, and Find My workflows."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos]

metadata:
  harness: [hermes]
---

# Apple Automation

Use this umbrella when the task involves controlling macOS applications, inspecting the GUI, using AppleScript/accessibility automation, taking screenshots, or working with Apple's Find My app.

## Canonical macOS computer-use workflow

1. Capture the current UI state before acting.
2. Prefer app-native automation, AppleScript, or accessibility selectors when reliable.
3. Fall back to coordinates only after visual verification.
4. Keep focus/window state explicit.
5. Verify the result with a screenshot or UI query.
6. Avoid destructive or privacy-sensitive actions unless the user explicitly asked.

Full prior macOS computer-use recipe: `references/macos-computer-use.md`.

## Find My / device-location workflow

For locating Apple devices or AirTags:

1. Open Find My and choose the correct tab: People, Devices, or Items.
2. Use AppleScript/UI automation when possible, otherwise screenshot and inspect visually.
3. Report uncertainty clearly; UI-derived locations can be stale or approximate.
4. Do not infer movement or identity beyond what the app shows.

Full prior Find My recipe: `references/findmy.md`.

## Verification checklist

- [ ] macOS is the active execution environment
- [ ] Accessibility/automation prerequisites were checked when required
- [ ] Screenshot or app state was observed before and after actions
- [ ] Privacy-sensitive details were only surfaced when requested
