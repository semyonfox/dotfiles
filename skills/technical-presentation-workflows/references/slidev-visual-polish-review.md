# Slidev visual polish review pattern

Use after an interview/demo deck is mostly correct but Semyon asks for slide-by-slide polish or complains that something “could be centered”, cramped, or visually awkward.

## Pattern from OghmaNotes `:3037` polish

1. Delegate a browser-based slide-by-slide visual review when time allows, but keep the scope narrow: layout/legibility only, no story rewrite.
2. Ask the reviewer to find concrete issues: centering, empty reveal states, clipped content, cramped cards, diagram sizing, title/body balance, too-heavy code blocks, inconsistent spacing.
3. Apply only high-confidence fixes quickly:
   - center cover subtitle/badge rows under centered titles;
   - avoid initial title-only slides and single-left-card reveal states in interview decks;
   - make card groups visible by default when cards form the slide’s basic layout;
   - reserve `v-click` for final takeaway lines, diagrams, code highlights, or optional detail rather than every card;
   - add a little margin above diagram viewers so labels/controls do not press against cards;
   - compress overcrowded horizontal flows, e.g. merge five tiny cards into four clearer cards;
   - make muted explanatory lines above code blocks more visible when they carry the key idea.
4. Rebuild and run SVG/theme checks.
5. Browser-check at least the cover and one representative card slide after fixes; do not rely on build output.

## Pitfall

Subtle reveal animations are good, but revealing every card one by one can make the first state look broken or empty in an interview. For architecture walkthroughs, the slide should look coherent immediately; use reveals to pace emphasis, not to hide the layout.
