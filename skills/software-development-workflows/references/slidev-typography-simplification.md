# Slidev interview deck typography and simplification pass

Use this when Semyon says a technical/demo deck looks too complex, childish, AI-smelly, badly spaced, or typographically weak.

## Typography principle

From Semyon's WebExpo typography notes: good typography quietly earns attention. It should not shout through heavy weights, decorative accents, noisy cards, or novelty effects. Users should not have to fight contrast, tiny labels, busy backgrounds, opacity, or weak hierarchy.

## Practical CSS defaults

For interview/demo decks, prefer a calm sans stack and restrained scale:

```css
.slidev-layout {
  font-family: Inter, Roboto, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  font-feature-settings: "kern" 1, "liga" 1, "calt" 1;
  text-rendering: optimizeLegibility;
  padding: 2.1rem 2.65rem;
}
.slidev-layout h1 { font-weight: 680; line-height: 1.08; letter-spacing: -0.025em; }
.slidev-layout h2 { font-weight: 650; line-height: 1.16; }
.slidev-layout h3 { font-weight: 620; line-height: 1.28; }
.slidev-layout p, .slidev-layout li { line-height: 1.52; }
```

Avoid persistent `font-weight: 900/800`, tight `.98` line-height, decorative dots after every heading, chunky orange borders, glowy cards, or visible presenter/talk-track UI.

## Simplification workflow

1. Cut the main path to the minimum interview story, usually 6–8 slides.
2. Keep one concrete code/proof slide; move broad architecture history and extra integrations to speaker notes or appendix/back-pocket context.
3. Replace unreadable full architecture/ERD/RAG diagrams with simplified boundary diagrams or card/flow layouts.
4. Put explanation in Slidev presenter notes (`<!-- ... -->`), not visible body text.
5. Visually verify title, a card slide, a dense diagram/flow slide, and the code slide in the served deck.

## OghmaNotes-specific pattern that generalized

For an SRE interview deck, the cleaner flow was:

1. Title / reliability walkthrough
2. Interview story
3. Current system boundary
4. Deployment and quality gates
5. Async ingestion path
6. Safe worker claim code proof
7. What I would harden next

Move architecture evolution, full RAG sequence, Canvas/MCP diagrams, and full ERD out of the main path unless the interviewer asks.

## Verification traps

- A diagram may technically fit but still be too tiny to read; replace it with a purpose-built simple SVG or native card/flow layout.
- Slidev/Shiki can render code blocks with poor contrast after theme changes; inspect the actual browser and override `.slidev-code-wrapper pre`, `.shiki`, `code`, and spans if needed.
- If custom SVG zoom components are useful for dense diagrams, hide demo-like toolbars/buttons for the formal deck path; controls can make the artifact feel like a product demo rather than an interview presentation.
