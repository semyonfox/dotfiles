---
name: linux-font-rendering-troubleshooting
description: "Use when Linux app or browser fonts render incorrectly."
version: 1.0.0
created_by: agent

metadata:
  harness: [hermes]
---

# Linux Font Rendering Troubleshooting

Use when browser chrome, a desktop application's native UI, or webpage text renders with an unexpected serif, bitmap, or monospaced face on Linux.

## Principle: identify the rendering layer first

Do not infer the responsible layer from `fc-match` alone. Distinguish:

1. **Webpage CSS/content** — site stylesheet, extension-injected CSS, and browser page font preferences.
2. **Browser-native UI** — tabs, sidebar/tab rail, toolbar, bookmarks, menus, and dialogs. These may ignore webpage font preferences.
3. **Toolkit/desktop UI** — GTK settings, GSettings, Qt/qtct, compositor/launcher styling.
4. **Fontconfig selection** — aliases, substitution rules, fonts that are unexpectedly discovered, rendering/hinting configuration.
5. **Application/upstream regression** — an implementation bug outside local configuration.

A font migration can add legacy font files with generic family names. Before assuming the migration is harmless, query generic families (`sans-serif`, `serif`, `monospace`, `system-ui`, `ui-sans-serif`) and identify the winning file path.

## Evidence-first workflow

1. Capture the *specific affected UI surface* before changing anything. A full screenshot is useful, but crop or name the target: native tab strip, bookmark bar, browser page, etc.
2. Inventory browser profile settings only while the application is fully closed. Re-read them after relaunch: Chromium-derived apps can regenerate platform defaults or overwrite manual edits at shutdown.
3. Check active configuration layers: browser profile preferences and policy paths; launcher command line/environment; GTK 3/4 settings and GSettings; Qt settings; user and system Fontconfig; browser extensions and user CSS.
4. Make one scoped change at a time and restart the application cleanly. Re-capture the exact target surface. Do **not** report success solely because a JSON preference, Fontconfig query, or process restart looks correct.
5. If native UI remains wrong after the profile/toolkit/Fontconfig inventory, stop layering broad aliases or copying more fonts. Search the application's upstream issue tracker using the observed UI surface, Linux distribution, version, and exact symptom.
6. For a suspected Fontconfig/package regression, record the exact installed package version and match it to an upstream report before proposing a downgrade. A system-library rollback needs explicit approval, a reversible package-manager plan, and a post-change screenshot check. Do not describe a third-party report of a downgrade as a verified fix until it is actually exercised on the target machine.

## Safety and scope

- Keep browser-only fixes browser-scoped where possible. Do not change generic `monospace` globally merely to alter browser chrome; terminals, launchers, editors, and code views legitimately depend on it.
- Do not delete migrated fonts on appearance alone. Move or exclude a suspect font only after a query identifies it as the selected face and a visual check confirms the result.
- Preserve intentional terminal/Waybar/Rofi font choices unless the user explicitly asks to alter them.
- Do not use or request credentials exposed in chat to perform package administration.

## Reference

- `references/helium-fontconfig-monospace-case.md` — an upstream-issue correlation for Helium on Arch/CachyOS, retained as investigation evidence rather than a confirmed local remediation.
