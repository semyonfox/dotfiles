# Generated demo artifacts: galleries vs Slidev decks

Use this when Semyon asks for generated diagrams/images/webpages to support an interview, demo, or examiner presentation.

## Lessons from the OghmaNotes diagram handoff

- Treat generated HTML galleries as **artifact browsers**, not polished demos. They are good for verifying and browsing many rendered files, but weak for an interview narrative.
- When the goal is to impress examiners/interviewers while staying steerable, prefer a **Slidev deck** or similar slide-native artifact:
  - modular opening slide: “pick product / architecture / code / database / infra”;
  - rendered architecture diagrams;
  - focused ERDs;
  - real code snippets with stepped highlights;
  - appendix/index diagram for open-ended steering.
- Keep the deck versatile: the interviewer should be able to steer the path rather than being forced through one linear sales pitch.
- Avoid “AI dashboard theatre”: gradients, glowy cards, overproduced copy, and filler marketing language. Use plain, confident, technical wording.

## Style pitfalls

- Dark grey page backgrounds plus **white SVG/PNG diagram canvases** can look mismatched. If diagrams are rendered with white backgrounds, either:
  - use a light/neutral slide theme, or
  - re-render diagrams with a theme/background that matches the page.
- “Simple” does not always mean “bare HTML.” For interview demos, simple means low-friction and credible: clean slide layout, readable diagrams, short descriptions, and quick navigation.
- If the user asks to “make the webpage simpler” after a generated gallery was opened, edit the generated gallery/deck first — do not assume they mean the app homepage.

## Practical workflow

1. Locate or generate formal Mermaid `.mmd` diagrams.
2. Render them to real SVG/PNG with `@mermaid-js/mermaid-cli`; keep `.mmd` sources alongside rendered files.
3. Build a Slidev deck when the audience is interview/demo/examiner-facing.
4. Include code snippets only if they demonstrate real engineering decisions, e.g.:
   - worker locking with `FOR UPDATE SKIP LOCKED`;
   - vector-store boundary and Qdrant collection config;
   - schema contract tests proving current DB assumptions.
5. Build/serve the deck and open it on the target machine. Verify assets are not missing.

## Minimum verification

- Deck build succeeds (`npm run build` or equivalent).
- Rendered diagrams exist and are referenced by the deck.
- At least one browser fetch/open succeeds on the target machine.
- The final path and URL are reported clearly.
