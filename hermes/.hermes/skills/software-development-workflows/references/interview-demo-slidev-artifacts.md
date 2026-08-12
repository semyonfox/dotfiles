# Interview/demo artifact decks from generated diagrams

Use this when Semyon is turning repo diagrams/screenshots into a presentation/demo artifact for interviews or exams.

## Key lessons

- Anchor the surface first: if the session has generated/opened a temporary gallery or deck, "the webpage" usually means that artifact, not the production app homepage.
- Prefer a purpose-built demo deck over a static image gallery when the goal is to impress interviewers/examiners. A gallery is good for file review; a deck is better for live steering.
- Slidev is Vue-based and is a good fit for this class of technical demo: Markdown slides, Vue components, code highlighting/line stepping, presenter/drawing tools, and easy custom components.
- Keep style intentional but not over-produced. Semyon may ask for "barely styled HTML" for quick viewing, but for interviews the artifact should be clean, readable, and technical rather than dashboard/glassmorphism/AI-looking.
- For white-background Mermaid SVGs on a dark page, either restore a light/neutral slide surface or render with a compatible theme. Do not force white diagrams onto dark grey if readability suffers.

## Recommended workflow

1. Generate formal Mermaid sources for architecture, data/ERD, workflow, deployment, and route/overview diagrams.
2. Render real SVG/PNG assets with Mermaid CLI; keep `.mmd` source links available.
3. If the user wants a live interview artifact, build a Slidev deck rather than just an HTML gallery.
4. Structure the deck as routes interviewers can steer into, not one rigid script:
   - Product story
   - Architecture/system boundaries
   - Database/ERD
   - Code/engineering depth
   - Deployment/operations
5. Include short, real code snippets from the repo where useful: worker locking, vector-store boundary, auth/rate-limit/API shape, schema contract tests.
6. Add a chat-facing route reference after building the deck: "go to slide X for route Y". This is more useful than cluttering the deck with too many modular chooser cards.
7. Verify the artifact where it will be used: build the deck, serve it locally on the target machine, open it in the intended browser, and confirm URLs/assets resolve.

## Useful Slidev pattern: zoomable SVG component

For diagrams that are too large to read on one slide, add a small Vue component that wraps an SVG/image and supports:

- drag to pan
- mouse wheel to zoom
- `L` to toggle a laser pointer
- `R` to reset zoom/pan

This makes ERDs and architecture diagrams usable live without leaving the deck. The component should keep controls minimal and visible: a title, one-line hint, and reset button.

## Pitfalls

- Do not bury the user in a file dump when they need a demo narrative.
- Do not over-style with gradients, cards, shadows, or "AI dashboard" polish if the user asks for simple and direct.
- Do not remove all polish if the result makes diagrams unreadable; readability wins.
- Do not create a production app change unless the user explicitly asks for the app/site. Generated decks and galleries are separate artifacts.
