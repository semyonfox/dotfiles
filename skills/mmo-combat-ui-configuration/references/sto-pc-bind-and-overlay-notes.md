# STO PC: bindings, options, and automation-overlay notes

## Verified STO bind workflow

- A default/fresh character may write an empty `space.txt` when `/bind_save_file space.txt` is issued. It indicates no serialised **custom** records, not a lack of default controls.
- A valid custom file can be loaded with `/bind_load_file <file>` from the STO `Live/` directory. **Proof standard:** immediately use `/bind_save_file <new-file>` and inspect that new export for the intended active lines. File presence and input-delivery reports are not sufficient.
- Verified active command syntax in the 2026-08 PC client:

```text
1 "+TrayExecByTray 0 0"
F1 "+TrayExecByTray 1 0"
Space "GenSendMessage HUD_Root FireAll $$ +Power_Exec Distribute_Shields $$ +TrayExecByTray 1 0 ..."
```

- `TrayExecByTray` uses zero-based tray and slot indices in saved exports. A `Space` hybrid bind can retain normal fire-all, distribute shields, and cycle a separate utility row.
- The STO client export normalizes the source format (e.g. appends a second empty-string column), so compare command content, not byte-for-byte source files.

## Recommended hybrid policy

- Use the number row for intentional primary actions.
- Use a secondary row for non-emergency utility. Spacebar may cycle that utility row only when it contains short, target-safe, non-toggle upkeep powers.
- Manual-only: cloak, Gravity Well or other placement-sensitive control, Evasive/escape, panic survival, teleports, summons, long clickies, and toggles.
- Do not defer a requested safe spacebar bind because the current character has empty utility slots: it remains inert until slots are populated.

## Verification language and context boundaries

- `bind_load_file` followed by a fresh `bind_save_file` proves the client retained a custom command mapping. It does **not** prove the player can see an effect if the referenced tray slots are empty or their commands are context-specific.
- In STO, a spacebar loop containing `FireAll` and `Distribute_Shields` is a **space** upkeep bind. It may execute globally, but those two actions do nothing on ground. Ground should retain manual weapon, grenade, kit, heal, and positioning actions unless a known safe ground upkeep power is deliberately added.
- The normal Options → Key Binds panel may omit chat-loaded custom chains; opening it after loading is not verification. Cancel it unless an explicit UI setting was intentionally changed, since Apply can overwrite stale normal-panel state.
- For a player who asks "what do I have right now?", inspect Powers/Stations/Equipment or mouse-over tooltips—not bare hotbar art. Icon-only identification is not sufficient evidence.

## Mission-instance recovery

When an escort objective has stopped advancing:

1. Capture the live scene and tracker.
2. Confirm whether the required NPCs, enemy wave, marker, and interaction prompt are actually present at the expected location.
3. If the correct area is empty and required entities are absent, do not suggest wandering or repeated combat. Open the mission journal and inspect In Progress for replay/transwarp/reset/abandon controls.
4. Use the least destructive reset/replay route available; state exactly what was observed before calling it a bug.

## Options and configuration order

1. Inspect the live ship/ground trays and actual ability names.
2. Set camera/mouse and HUD usability first through clearly labelled in-game settings.
3. Load/document the base bind layout; re-export it to verify installation.
4. Populate the spacebar utility row only with appropriate actual abilities as they unlock.
5. Separately verify ground mode/ground bindings; never assume a space layout is ideal on foot.
6. Exit menus/HUD editor and capture clean normal gameplay.

## Remote-control constraints

- In this setup, STO exposed only window-level accessibility metadata; its canvas UI required fresh screenshot-grounded coordinates.
- Background text input to STO was unavailable; cua-driver required explicit foreground escalation. Only do that with user approval or an unambiguous instruction to proceed.
- cua-driver’s agent cursor can leave an animated trail. End every declared session, disable the cursor overlay, and verify a clean final game capture.

## Files and backups observed

- Game root: `~/.local/share/Steam/steamapps/common/Star Trek Online/Star Trek Online/Live/`
- Preferences: `localdata/Gameprefs.Pref`; it does not necessarily contain action-bar bindings.
- Timestamp-copy every modified or exported bind/preferences file before loading a new layout.
