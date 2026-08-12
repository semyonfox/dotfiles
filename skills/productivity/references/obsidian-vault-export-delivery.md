# Obsidian vault export and friend-friendly delivery

Use this when the user asks to pull an Obsidian vault or similar note repository, bundle a subset, and send it through a messaging surface.

## Workflow

1. Resolve the canonical source first.
   - If the user says “my Obsidian vault from GitHub”, inspect authenticated GitHub repos for likely vault repos before asking.
   - Clone to a scratch path, not into the home directory unless the user requested a working checkout.

2. Find the requested content by path and content search.
   - Search folder names and file contents for event/project terms.
   - If notes reference external local source directories, verify whether those directories actually exist before assuming transcripts/media are included.

3. Package for the recipient’s platform.
   - Prefer `.zip` for non-Linux recipients and phone sharing.
   - Preserve a clean top-level path inside the archive so extraction is understandable.
   - If the system `zip` binary is missing, use Python’s stdlib `zipfile` as a packaging fallback rather than switching to tar.

4. Verify before sending.
   - Count files in the source subset.
   - Inspect the archive namelist/count after creation.
   - Be explicit about what is included: notes only, transcripts, images, videos, etc.

5. Delivery surface discipline.
   - For the current platform, attach via `MEDIA:/absolute/path`.
   - If the user asks for a specific other channel/person, list available messaging targets first; do not guess Discord/Telegram target IDs.
   - Keep a stable copy outside `/tmp` if the user will need to resend later, e.g. `~/share/<name>.zip`.

## Cross-channel delivery fallback

Use this when the user wants the bundle sent somewhere other than the current chat and the messaging tool/runtime is not already configured.

- Inspect legacy app config for whether a token is stored directly or only referenced by environment variable. Many configs store only a pointer such as `DISCORD_BOT_TOKEN`, not the secret value.
- Never print recovered bot tokens or paste them into chat. Validate them with a harmless identity endpoint, then store them in the appropriate env/config location if the user has authorized migration.
- If a gateway/runtime does not reload newly written env vars, do not claim the platform integration is working normally. Either ask the user to restart it externally, or use a direct platform API upload as a one-off fallback when safe.
- Verify direct API uploads by reading the saved response JSON and extracting message/channel/attachment IDs, not just by trusting an HTTP status line.

## Pitfalls from session experience

- Do not imply “all WebExpo content” includes transcripts or videos just because the notes were generated from subtitles/slide timings. Check for `.vtt`, `.srt`, `.txt`, `.mp4`, `.mov`, `.webm`, etc., or referenced local source directories.
- Android file pickers can behave badly with freshly downloaded chat attachments. A stable server-side copy plus direct delivery to another channel may be needed.
- Messaging target availability is runtime-specific: `send_message(action='list')` may show only WhatsApp even if an old config mentions Discord.
- Missing local binaries like `zip` are setup state, not a durable limitation. Use a fallback and continue.
