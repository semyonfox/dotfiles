# Slidev story micro-iterations

Use this pattern when Semyon asks for “some more iterations” on an already-simplified Slidev architecture/interview deck, especially when a `STORY_HANDOVER.md` exists.

## Trigger

- The deck is already close and has a main story + appendix/back-pocket structure.
- Semyon asks for more iterations, polish, or familiarisation rather than a rewrite.
- There is a narrative handover file such as `STORY_HANDOVER.md` plus an operational `HANDOVER.md`.

## Workflow

1. Read both handovers first:
   - `STORY_HANDOVER.md` for narrative truth, what emotional/product pressure to preserve, and what not to lose.
   - `HANDOVER.md` for operational state, commands, known warnings, and current deck structure.
2. Read `slides.md`, `style.css`, and relevant components before editing.
3. Make one or two **small visible improvements** that strengthen the story without adding a new slide or restoring complexity.
4. Prefer compact visual anchors over paragraphs:
   - a short product-promise pill/hook
   - a five-step boundary flow
   - a proof strip under code
   - a small current/past/target label
5. Keep the main flow lean; move detail into comments/speaker notes or appendix.
6. Build, serve/check HTTP, and visually inspect the affected slides.
7. Update both handovers with what changed and the verification state.

## Good micro-patterns from the Oghma deck

### Product-pressure hook

Use when a technical story needs the human/user pressure made visible without becoming salesy:

```md
<div class="story-line">
  <span>Product promise</span>
  <strong>“I added coursework; I should be able to study from it soon.”</strong>
</div>
```

### Boundary flow

Use when an architecture boundary needs to be concrete but not diagram-heavy:

```md
<div class="boundary-flow">
  <div><strong>Request</strong><span>accept intent</span></div>
  <div><strong>Status</strong><span>persist progress</span></div>
  <div><strong>Queue</strong><span>retry work</span></div>
  <div><strong>Worker</strong><span>extract + embed</span></div>
  <div><strong>Searchable</strong><span>safe to retrieve</span></div>
</div>
```

### Proof strip under code

Use when a code slide needs the takeaway labelled without adding more code:

```md
<div class="proof-strip">
  <span>Dispatch: Redis/BullMQ</span>
  <span>Process: Node worker</span>
  <span>Recover: Postgres state</span>
</div>
```

## Visual constraints

- Dark, restrained, sparse.
- Orange only as tiny structure/accent.
- No new visible complexity unless the story becomes clearer.
- No dashboard polish, bento gimmicks, gradients, glows, or giant accent borders.
- One idea per slide; presenter notes carry the explanation.

## Verification checklist

- `npm run build` passes.
- Existing hosted deck root returns HTTP 200 if a server/service exists.
- Any changed diagram/SVG routes return HTTP 200.
- Browser visual QA covers at least the edited slides plus title.
- Check for clipping, crowded arrows, low-contrast code, and too-salesy visible wording.

## Handover update

After the pass, add a timestamped summary to both:

- `HANDOVER.md`: files changed, latest visible changes, verification.
- `STORY_HANDOVER.md`: latest narrative/verification context so the next agent understands why the new anchors exist.
