# Slidev interview story rescue: project first, architecture second

Use this when Semyon says a deck has the correct facts/styling but still feels worse than an older version because it is too diagram-first, too AWS/provider-first, or too jargon-heavy.

## Trigger signals

- “This is still not as good as the other one.”
- “The other one had better: this is OghmaNotes, here are the problems, but we did this.”
- “Give an intro to the project, then build on it.”
- “Assume this architecture is correct.”
- “Ready for an interview in 2 hours.”

## Fast rescue pattern

1. Keep the trusted deck’s facts, diagrams, and visual system as the source of truth.
2. Reorder the story around the project, not the cloud provider:
   - what the project is
   - what users are trying to do
   - what problems hide inside that product
   - what broke in production / under platform constraints
   - what architecture change was made
   - how workers/status/logs/security/deploy support that change
   - what evolved and what would be hardened next
3. Reduce visible AWS/provider wording until the architecture slide is earned by the product-pressure slides.
4. Use simple “we did this” language on visible slides. Avoid noun-stack headings like “AWS worker delivery” unless the previous slide has already explained why the worker exists.
5. Put tense/proof caveats in speaker notes, not in big visible slide text, unless the distinction is critical.
6. Keep diagrams as explanation aids, not the opening move.

## Good interview slide flow

A strong Oghma-style interview deck can be:

1. Project title / one-line identity
2. What OghmaNotes is
3. The problems hiding inside it
4. Architecture shape as the answer
5. What broke the first design
6. What changed
7. Worker delivery in practice
8. Chat/serverless timeout exception
9. Debugging/visibility lessons
10. Security/data-boundary lesson
11. Operating/release flow
12. Architecture evolution
13. Honest hardening / what to improve
14. Optional full map
15. Optional schema/data ownership

## Speaker-note pattern

Make notes jumpable under pressure:

- `QUICK`: default 20–40 second talk track
- `LOW-TIME`: one sentence
- `ANECDOTE`: casual colour/story
- `LONG`: deeper explanation if they lean in
- `ACCURACY GUARD`: tense/proof caveats and what not to overclaim
- `TRANSITION`: optional bridge to next slide

## Pitfalls

- Do not open with the AWS diagram if the user says the older deck had the better story. Start with the product and its hidden problems.
- Do not treat “architecture is correct” as “make the deck architecture-first.” It means preserve correctness while improving narrative.
- Do not make visible slides carry every caveat. Put current-vs-historical and proof nuance in notes so the live talk stays human.
- Do not average two decks mechanically. Borrow story beats from the better narrative deck, but keep the trusted deck’s facts/styling when they conflict.
- For urgent interview polish, prefer a coherent 13–15 slide story that builds naturally over adding more appendix diagrams or technical detail.
