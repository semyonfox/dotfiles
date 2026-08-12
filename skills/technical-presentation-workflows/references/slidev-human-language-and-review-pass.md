# Slidev human-language and external review pass

Use when a Slidev architecture deck is already structurally close, but Semyon says the wording feels unnatural, over-written, too full of punctuation, or asks for outside opinions.

## What happened

In the OghmaNotes deck polish session, the deck had a solid architecture arc but visible copy still felt too much like internal architecture notes. Semyon corrected:

- make the text more human and natural
- remove semicolon-heavy phrasing
- do not use a slide title like `What I would talk through if asked` in an actual presentation
- keep diagram slides in the deck, but remove visible `Optional:` labels
- ask Fable and a delegated reviewer for blunt opinions

## Durable lessons

### Human-language cleanup

For visible slide copy:

- Prefer spoken, direct phrasing over polished-document phrasing.
- Avoid semicolon-heavy lines; split into normal sentences or use commas.
- Avoid visible scaffolding such as `if asked`, `optional`, `talk through`, `presenter notes`, or `if there is time` unless the slide is explicitly an appendix navigation slide.
- A closing slide should be part of the talk, e.g. `What I’d harden next`, not `What I would talk through if asked`.
- If the deck is about Semyon’s personal project, check pronoun consistency. `I` is often stronger than vague `we` unless there really was a team.

### Diagram/back-pocket slides

If Semyon wants diagrams available but not mandatory:

- Keep the diagram slides in the deck.
- Remove visible `Optional:` from slide titles.
- Put time-permitting / if-needed guidance in speaker notes, not visible copy.
- Make visible subtitles audience-facing, e.g. `The wider dependency map: clients, app, workers, data plane, providers`, not `If there is time, use this...`.
- Treat these as back-pocket slides after the real close unless Semyon explicitly wants them in the main flow.

### One-liner/takeaway discipline

Takeaway lines are useful only when they synthesize a decision or tradeoff. They become tiring when every slide ends on a mic-drop. On dense diagram slides, skip visible one-liners unless they clarify the diagram.

### External opinion pattern

When Semyon asks for Fable / another model / delegated agent opinions on a deck:

1. Use a real external path when available, read-only.
2. Also delegate one independent review agent if requested.
3. Ask reviewers for blunt, practical opinions: what works, what feels weak/cringe/confusing, whether recent changes were good, and top concrete improvements.
4. Report their opinions separately, then synthesize the overlap.
5. Do not hide tool/model failure: if a requested model path fails, say so, then use an available configured path if possible.

## Review heuristics that emerged

Blunt reviewers flagged these as high-value checks:

- Is current vs historical architecture visible enough, or only hidden in notes?
- Does the single code slide show real/current code, or illustrative pseudo-code from a retired stack?
- Does the layout rhythm become repetitive: cards + takeaway on every slide?
- Are diagram slides audience-facing, or do they leak presenter instructions?
- Does the final slide end the talk credibly, rather than acting like a hidden appendix prompt?
