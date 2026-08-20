---
name: flatmmo-userscript-handoff
description: "Use when building, installing, or handing off the FlatMMO Mega Helper userscript to Helium, Tampermonkey, or Violentmonkey."

metadata:
  harness: [codex]
---

# FlatMMO Userscript Handoff

Work from the `flatmmo-mega-helper` repo root.

1. Prefer PC loading:

   ```sh
   npm run ship:helium
   ```

   It runs `npm run check` and `npm run build`, copies the built script to PC `10.0.0.15`, starts PC-local `python3 -m http.server` in Downloads, and opens its cache-busted URL in Helium via Hyprland.

2. If the PC is unreachable or `ship:helium` unavailable, hand off locally:

   ```sh
   npm run ship:user
   ```

   It checks, builds, and copies `dist/flatmmo-mega-helper.user.js` to `~/Downloads/flatmmo-mega-helper.user.js`.

3. If `ship:user` is unavailable:

   ```sh
   npm run check
   npm run build
   mkdir -p ~/Downloads
   cp dist/flatmmo-mega-helper.user.js ~/Downloads/flatmmo-mega-helper.user.js
   ```

4. Verify the copied script and header:

   ```sh
   ls -l ~/Downloads/flatmmo-mega-helper.user.js
   head -12 ~/Downloads/flatmmo-mega-helper.user.js
   ```

For PC loading, verify remote history includes `Script Installation | Tampermonkey` and the current cache-busted URL. Tell the user whether that install page loaded. They must still confirm the Tampermonkey/Violentmonkey install or update prompt and reload `https://flatmmo.com/play.php`, unless Codex can safely inspect and click it. Raw JavaScript in a browser is not a successful install.

Use a PC-local server: localhost in the Codex environment cannot serve Helium on the desktop PC. If SSH is unavailable, copy the `.user.js` to Downloads. If the environment truly controls the desktop browser, opening that file is acceptable, but report whether an install/update prompt was actually visible.
