---
name: mmo-combat-ui-configuration
description: "Use when configuring MMO controls, camera, HUD, and hotbars."
version: 1.0.0
author: Hermes Agent
license: MIT
created_by: agent

metadata:
  harness: [hermes]
---

# MMO Combat UI Configuration

## When to Use

Use when tuning a player's controls, camera, HUD, hotbars, and combat input for a live MMO. The deliverable is a usable, verified in-game configuration—not a proposed layout or a hand-waved config-file edit.

## Outcome standard

1. Inspect the **live game UI** and the current action bars before altering bindings.
2. Preserve a compact semantic layout, but bind only abilities/items that genuinely exist on the active character and tray.
3. Configure space/vehicle and ground/on-foot contexts independently when the game supports both.
4. Make camera and HUD changes before asking the player to learn an ability rotation.
5. After each mutation, visually verify the setting or binding landed. A successful input-delivery report is not proof.
6. Finish in normal gameplay view—never leave menus, HUD-edit mode, or an automation overlay active.

## Safe binding strategy

- Separate **semantic jobs** from specific current abilities. Example jobs: primary burst, control, movement, emergency survival, utility/stealth.
- Reserve stable keys for future progression only after checking that they do not collide with an existing essential command.
- Do not bind named endgame abilities that the character has not unlocked; retain the desired semantic slot and fill it later from the actual tray.
- Do not rely on an exported bind file as the only source of truth. A fresh/default character can export an empty file despite having normal default controls.
- Prefer the game's own Key Binds panel for one-off normal bindings. For an established, documented command grammar, a deliberately authored bind file is valid—but load it, then prove the live client accepted it by immediately re-exporting and inspecting the resulting active lines.
- Treat UI settings and chat-command binds as separate stores unless the specific game documents otherwise. In STO, `/bind_load_file` custom command chains may be active yet absent from Options → Key Binds; verify them with a fresh `/bind_save_file`, not by assuming the panel is a complete viewer. If opening Options after a chat-bind load, do not click Apply on a stale panel; cancel/close it unless you deliberately changed an explicit setting.
- For a pro-style hybrid layout, keep primary rotation, positioning, control, cloak, and panic survival manual. A repeated utility key (often Space) may safely fire weapons/shield distribution plus a dedicated row of short, target-safe upkeep powers; never fill that row with placement-sensitive control, cloak, escape, long defensive cooldowns, teleports, or toggles.

## Camera and HUD pass

1. Open the game options and identify the exact camera/mouse/control setting names in the current client UI.
2. Check target-follow/target-camera behavior, mouse steering/turning, zoom/distance, inversion, and any separate ground shooter/aim mode.
3. Apply only settings that are clearly labelled and visually confirm their values after applying.
4. Enter HUD-edit mode only when components are identifiable. Move the minimum: player state, target state, and active combat tray toward the central lower play area; preserve map/chat/objective readability.
5. Exit HUD-edit mode and capture normal gameplay to confirm the result is clean.

## Computer-use discipline for games

- Game canvases commonly do not expose usable accessibility elements. Treat coordinate actions as high-risk and use a fresh screenshot before every action.
- Begin background-first. If the driver reports that background injection is unavailable, foreground input is an explicit escalation and should only happen with user approval or a clear instruction to proceed.
- Automation cursor overlays/trails can contaminate the play view. Start sessions only when needed, end every session, and disable the overlay when the task completes. Verify with a final clean capture.
- Do not interact with login, account, payment, security, or 2FA interfaces.

## Player-facing explanation and reporting

- Start with the direct answer the player asked for. If they ask what a tray is, explain it as the visible hotbar row before discussing bind-file internals.
- Distinguish **installed**, **verified mapping**, and **combat-tested**. An in-game re-export proves the mapping is installed; it does not prove an empty utility row has a visible effect in combat.
- Never identify abilities from icons alone when a precise answer matters. Inspect the live Powers/Stations/Equipment screen or state the icon is uncertain.
- Do not claim a camera or HUD fix occurred unless the exact in-game control was changed and then visually confirmed.
- Ground and space use different combat contexts. A global custom bind may execute in both, but a spacebar loop built around Fire All and shield distribution provides no ground benefit. Do not present it as a ground build; keep ground grenade, healing, kit, and positioning powers manual unless the player has an explicitly safe ground upkeep power.

Report in this order:

1. **Verdict:** what was actually changed and verified.
2. **Bindings:** context, key, and current assigned job/ability.
3. **Camera/HUD:** exact changed setting names and values.
4. **Deferred slots:** abilities not yet available and the condition for assigning them.
5. **Recovery:** backup/export paths if files were modified.

## Pitfalls

- Do not claim an empty bind export means a game has no bindings; it can mean no custom bindings were stored.
- Do not call a custom bind “working” merely because it loads. Say whether it is mapping-verified and whether its current trays contain abilities that can produce an observable combat result.
- If a mission/instance looks stalled, first inspect the live tracker, NPCs, markers, and enemies. If required escorts/spawns are absent at the correct location, treat it as an instance-state fault; use the mission journal’s replay/transwarp/reset route where present rather than telling the player to search indefinitely.
- Do not create a plausible bind file from memory and load it into a live character. Research and validate the game command grammar, then re-export after loading to prove the client retained it.
- Do not mistake a file being present for an installed bind; the authoritative check is a fresh in-game export showing the expected active command lines.
- When a player asks for a pro/meta layout, give the verdict and install/verify it before explaining the theory. Do not keep deferring a requested spacebar/utility bind merely because current tray slots are empty; empty slots are harmless if the bind itself is sound.
- Do not leave a menu or HUD arranger open after an interrupted configuration pass.
- Do not expose an agent cursor/trail in screenshots delivered to the player; clean it up first.

## References

- `references/sto-pc-bind-and-overlay-notes.md` — STO-specific details from the PC configuration session, including UI constraints and verified file behavior.
