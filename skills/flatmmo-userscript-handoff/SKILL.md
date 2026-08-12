---
name: flatmmo-userscript-handoff
description: "Use when build and hand off the FlatMMO Mega Helper userscript for Helium/browser installation. Use when working in the flatmmo-mega-helper repo after UI, automation, targeting, mining, loot, pathing, or command changes; when the user asks to put/update/install the script in their browser; or when the user mentions Helium, Downloads, userscript manager, Tampermonkey, or Violentmonkey."

metadata:
  harness: [codex]
---

# FlatMMO Userscript Handoff

## Workflow

1. Work from the `flatmmo-mega-helper` repo root.
2. Prefer the project command that loads the script into Helium on the user's PC:

   ```sh
   npm run ship:helium
   ```

   This runs `npm run check`, `npm run build`, copies the built script to the
   PC at `10.0.0.15`, starts a PC-local `python3 -m http.server` from the PC's
   Downloads folder, and opens the cache-busted URL in Helium via Hyprland.

3. If the PC is unreachable or `ship:helium` is unavailable, use the local
   Downloads handoff:

   ```sh
   npm run ship:user
   ```

   This runs `npm run check`, `npm run build`, and copies
   `dist/flatmmo-mega-helper.user.js` to
   `~/Downloads/flatmmo-mega-helper.user.js`.

4. If `ship:user` is unavailable, run the fallback sequence:

   ```sh
   npm run check
   npm run build
   mkdir -p ~/Downloads
   cp dist/flatmmo-mega-helper.user.js ~/Downloads/flatmmo-mega-helper.user.js
   ```

5. Verify the copied file exists and still has the userscript header:

   ```sh
   ls -l ~/Downloads/flatmmo-mega-helper.user.js
   head -12 ~/Downloads/flatmmo-mega-helper.user.js
   ```

6. For the PC-loaded flow, verify Helium received the install page by checking
   remote history for `Script Installation | Tampermonkey` and the current
   cache-busted URL.

7. Tell the user whether the Tampermonkey install page was loaded. The user must
   still confirm the install/update prompt and reload `https://flatmmo.com/play.php`
   unless Codex can safely inspect and click the prompt.

## Browser Notes

- Prefer the PC-local server opened through SSH/Hyprland when available. Serving
  localhost from the Codex environment is wrong when Helium is on the desktop PC;
  the server must run on the PC itself.
- If PC SSH is unavailable, fall back to copying the built `.user.js` to
  `~/Downloads`.
- Do not treat a browser tab showing raw JavaScript as a successful install.
  The user must confirm the update in Violentmonkey or Tampermonkey.
- If the environment truly has access to the user's desktop browser, opening the
  copied Downloads file is acceptable. Still report whether an install/update
  prompt was actually visible.
