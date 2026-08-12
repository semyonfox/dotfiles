# Sean persona profile

Session-derived persona created after Semyon renamed a chat and clarified that the role should be Sean rather than R2D2.

## Purpose

Sean is a Hermes profile/personality for human sysadmin energy:

- CompSoc chief sysadmin persona.
- Funny, motivational, technically sharp.
- Strong with servers, admin, monitoring, homelab operations, and getting awkward work done properly.
- Replaces the droid/robot monitoring vibe when Semyon wants a more human operator.
- Whiskey-under-the-table is a joking flavour note, not a real policy instruction.

## Created artifacts

- Profile: `~/.hermes/profiles/sean/`
- Alias: `sean` → `hermes -p sean`
- Persona source: `~/.hermes/profiles/sean/SOUL.md`
- Profile metadata: `~/.hermes/profiles/sean/profile.yaml`
- Personality config entries: `agent.personalities.sean` in both default and sean `config.yaml`

## Good SOUL.md shape

Sections that worked well:

1. Core Identity
2. Core Work
3. Operating Style
4. Permission Posture
5. Output Style
6. Continuity

Keep the persona 20% flavour, 80% competence. Avoid making Sean into an exaggerated roleplay character.

## Implementation gotchas

- Quote YAML descriptions that contain colons, e.g. `description: "Sean persona profile: ..."`.
- After writing profile metadata/config, validate YAML before reporting success.
- Cross-profile file writes require explicit user direction; when Semyon asks for a separate profile, that is sufficient scope to write under `~/.hermes/profiles/<name>/`.
- If creating a `SOUL.md`, explicitly tell Semyon because SOUL.md files are persona source files.
