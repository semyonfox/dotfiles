# Slidev midpoint deck merge pattern

Use when Semyon has two live deck variants and asks for an "in-between" version under time pressure.

## Trigger

- One deck has better styling/animations/visual polish.
- Another deck has better story/background/context.
- Semyon says one variant is more accepted as truth if claims conflict.

## Workflow

1. Identify both serving processes and project roots from ports/process cwd.
2. Read both `slides.md` and relevant CSS before editing.
3. Treat the explicitly trusted deck as the source of truth for factual claims and visual system.
4. Pull only the stronger narrative beats from the other deck:
   - product context
   - production bug / constraint story
   - before/after behaviour
   - ownership/security/logging lessons
   - concise closing takeaways
5. Avoid a full rewrite. Rebuild the flow as a small number of named slides, preserving the accepted deck's components, animation style, SVG fixes, and notes structure.
6. Keep visible slides lean; put background context into structured presenter notes.
7. Rebuild, re-run SVG theme checks if SVGs are involved, serve-check the target port, and visually inspect representative slides.
8. Update handover with exact deck roots, chosen source of truth, merged narrative beats, verification, and caveats.

## Notes structure

For interview/project decks, speaker notes should be jumpable:

- `QUICK` — default 10–20 second version.
- `LOW-TIME` — one sentence if rushed.
- `ANECDOTE` — casual story if the interviewer engages.
- `LONG` — deeper technical expansion.
- `ACCURACY GUARD` — tense/proof caveats, especially historical vs current infra.

## Pitfalls

- Do not average truth. If Semyon says one deck is the accepted factual source, use that for all conflicting architecture claims.
- Do not keep duplicate slides just because both versions had them; merge their purpose or delete one.
- Do not move valuable story back into visible paragraphs. Use presenter notes for context.
- Do not leave old appendix/back-pocket framing if the slides are only optional detail; label them as optional and skippable.
- Do not call the task done without at least a build and a quick visual check of representative slides.
