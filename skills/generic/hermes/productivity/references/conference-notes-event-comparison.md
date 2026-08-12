# Conference Notes → Local Event Comparison

Use this when Semyon asks whether a current/local event overlaps with something he previously saw at a conference, especially when he mentions Obsidian notes/transcripts.

## Workflow

1. Treat the local event page as the current source of truth.
   - Extract title, speaker, date/time, venue, stated audience, promised takeaways, and any registration details.
   - Prefer browser/snapshot extraction for dynamic booking pages when plain web extraction only returns template placeholders.

2. Search the Obsidian vault before answering from memory.
   - Likely path for WebExpo notes: `/home/semyon/obsidian/personal/WebExpo 2026/`.
   - Search terms should include the local event title words plus conceptual variants, e.g. `sales`, `funnel`, `leak`, `conversion`, `convert`, `growth`, `customer`, `pricing`, `story`, `product`.
   - Read the strongest matching note(s), not just filenames.

3. Compare at decision level, not just topic level.
   - Same topic? Same audience? Same maturity level?
   - Is the new event likely to add content, or mainly networking/local context?
   - What should Semyon ask if he goes, based on what he already knows?

4. Preserve useful reusable links in the answer.
   - Include the Obsidian file path when found.
   - Include the local event URL.
   - Keep the verdict blunt: go for content, go for networking, skip, or attend only if already nearby.

## Answer shape

- Identify the matching prior note/session.
- Short comparison table: prior talk vs local event.
- Extract the 5–8 highest-value notes from the prior transcript.
- Give a verdict and 3–5 sharp questions to ask at the event.
- If there is a second event aligned with Semyon's interests, call it out separately rather than burying it.

## Pitfalls

- Do not create a separate monitor/cron when the user is asking to tune an existing briefing/radar. Inspect existing jobs first and update the relevant one.
- Do not rely on web_extract alone for dynamic ClearBookings/PorterShed pages; browser snapshots can reveal the actual event text, speaker, and booking form.
- Do not overvalue repeated content. For PorterShed-style events, the room/networking may be more valuable than the talk itself.
