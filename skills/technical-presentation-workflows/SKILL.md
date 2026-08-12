---
name: technical-presentation-workflows
description: "Use when create, refine, verify, and hand off technical presentation decks for Semyon, especially Slidev/demo decks with architecture stories and restrained styling."

metadata:
  harness: [hermes]
---

# Technical presentation workflows

Use when Semyon asks to make, finesse, review, run, or hand off a technical deck, demo presentation, Slidev show, architecture walkthrough, or interview/project presentation.

## Default workflow

1. Inspect the existing deck before rewriting.
2. Identify the audience and core story.
3. If Semyon asks to **review**, **familiarise**, **look over**, or **give thoughts** on slides/docs, treat that as read-only: review the files, summarize understanding, flag issues/opportunities, and ask before editing. Do not touch `slides.md`, CSS, diagrams, or handover docs unless he explicitly asks for changes.
4. Preserve working content; make incremental improvements only when Semyon explicitly asks for an edit/pass/rewrite.
5. Delegate a design/technical pass only when useful, but verify the result yourself.
6. Edit the deck and supporting style files only after the edit scope is clear.
7. Build/run the deck after edits.
8. Visually inspect representative slides after edits.
9. If another agent/user will continue, write or update a concise handover file in the project only when requested or when actual edits were made.

Do not stop at “I made edits”; a deck task is not complete until it builds and at least key slides have been visually checked.

## Semyon's visual preference

For technical/demo decks, default to:

- dark grey/black background
- simple cards/panels
- subtle borders
- one restrained accent colour
- readable code and diagrams
- minimal transitions
- no gradients
- no glassmorphism
- no neon/glow-heavy “AI SaaS” styling
- no decorative clutter

Semyon likes concise, human, non-salesy decks. Prefer “credible engineering walkthrough” over “startup pitch”. When a deck is about a real project, lead with the project’s architecture, decision history, tradeoffs, failure boundaries, and implementation proof — not “look at me, this is for an interview” framing. If Semyon mentions Eidhne/project stories, treat that as a request for the system’s lived architecture narrative: why boundaries exist, what broke or could break, what decisions were made, and what the next engineering chapter is. Keep those stories as optional colour unless he explicitly asks for a product narrative: visible slides should stay architecture-first, while speaker notes carry background, failure modes, “if asked” branches, and side stories he can allude to or expand depending on the interview flow. When a deck feels like the story was slapped in, rewrite the slide sequence so each visible slide follows product pressure → architecture boundary → operational consequence.

When he asks for his portfolio style, use the portfolio’s restrained dark bento look: black/near-black background, subtle card borders, Inter-heavy headings, and fox-orange dots/small markers rather than large orange sidebars or AI-SaaS-looking accent bars. If a dark deck becomes too monochrome, restore orange as tiny structural accents (dots, chip borders, code highlights, understated inline marks), not as loud panels or chunky borders.

For project architecture walkthroughs, do not turn the deck into a sales pitch or product-promise pitch. Semyon is usually walking people through architecture of a real project he worked on, with engineering anecdotes and judgement. Prefer “here is how the system is shaped, what changed, what broke/could break, and why I made these decisions” over “here is the product promise / why this is impressive.”

## Slidev notes

References:

- `references/agy-gemini-visual-qa.md` captures the headless Antigravity/Gemini screenshot-review pattern: call `agy` directly like `claude -p`, choose Gemini thinking level per visual density, and keep Gemini as visual QA rather than final taste/implementation brain.
- `references/multi-model-visual-artifact-bakeoffs.md` captures the visual model bakeoff pattern: generate multiple HTML/SVG/deck artifacts, render screenshots with the same browser/viewport, cross-judge with a rubric plus pairwise/ranking, exclude self-scores, and build a contact-sheet/gallery for Semyon.
- `references/multimodel-visual-bakeoff-and-qa.md` captures the reusable multimodel visual bakeoff pattern: fresh prompt/theme, multiple artifact formats, Chrome screenshots, hosted/contact-sheet comparison, non-self rubric scoring, and pairwise/Elo benchmark guidance.
- `references/oghma-genesys-slidev-deck.md` captures a concrete OghmaNotes/Genesys Slidev deck pattern, including styling palette, SRE story shape, serving command, and verification checklist.
- `references/oghma-genesys-slidev-deck.md` captures a concrete OghmaNotes/Genesys Slidev deck pattern, including styling palette, SRE story shape, serving command, and verification checklist.
- `references/slidev-interview-deck-cleanup.md` captures the reusable interview-deck cleanup pattern: slideworthy visible content, proper speaker notes, SRE framing, portfolio-aligned styling, and anti-clipping diagram fixes.
- `references/slidev-dark-svg-typography.md` captures the Oghma dark-SVG/Inter typography pass: small orange accents, grey hierarchy, appendix heading scale, ZoomableSvg dark backgrounds, and SVG-internal dark overrides.
- `references/slidev-cleanup-visual-qa.md` captures concrete cleanup fixes: baseline-aligned orange card dots, handling `port already in use`, and rebuild/browser-check sequencing.
- `references/slidev-zoomable-svg-controls.md` captures the preferred clean ZoomableSvg pattern: visible small controls, bounded zoom, deliberate modifier wheel zoom, pan only after zoom, no cache-busting URL suffixes, and visual QA steps.
- `references/architecture-decision-story-reframe.md` captures the Oghma deck reframe pattern: turn interview/pitch wording into architecture decision stories, tradeoffs, failure boundaries, and implementation proof.
- `references/architecture-decision-story-reframe.md` captures the Oghma deck reframe pattern: turn interview/pitch wording into architecture decision stories, tradeoffs, failure boundaries, and implementation proof.
- `references/slidev-architecture-story-notes.md` captures the follow-up pattern for making architecture slides feel like one coherent product/system story while keeping visible slides lean and moving background/issues into optional speaker-note branches.
- `references/slidev-architecture-accuracy-audit.md` captures the repo-depth accuracy pass for Oghma-style architecture decks: verify current vs retired vs target infrastructure, fix BullMQ/Postgres queue confusion, update diagrams, and avoid observability overclaims.
- `references/slidev-story-micro-iterations.md` captures the small-iteration pattern for already-close Slidev decks: read story/operational handovers, add compact product-pressure/boundary/proof anchors, verify visually, and update handovers.
- `references/slidev-midpoint-deck-merge.md` captures the pattern for merging two live deck variants: keep the trusted deck's facts/styling, borrow the other deck's stronger story/context, preserve structured notes, and verify quickly.
- `references/slidev-interview-story-rescue.md` captures the urgent rescue pattern for Oghma-style interview decks that are factually correct but still too diagram/provider-first: start with the project, then the hidden problems, then the architecture response, with jumpable speaker notes.
- `references/slidev-visual-polish-review.md` captures the slide-by-slide visual polish pattern: delegate layout review, remove empty reveal states, center cover elements, de-cramp flows, add diagram breathing room, and verify visually.
- `references/slidev-human-language-and-review-pass.md` captures the follow-up pattern for making visible slide copy sound natural/spoken, removing visible scaffolding such as `optional` / `if asked`, keeping diagram slides as back-pocket material, and collecting blunt Fable/delegated-review opinions.
- `references/slidev-handover-public-sharing.md` captures the handover + temporary public-sharing pattern: keep slide flow current, document tunnel/static services, verify public root plus assets, browser-check for interstitials, and include stop/remove commands.

For Slidev projects:

- When a project has both narrative and operational handover files (for example `STORY_HANDOVER.md` plus `HANDOVER.md`), read both before editing: the story file protects the emotional/product/architecture truth, while the operational handover gives commands, current state, and known warnings.
- If Semyon explicitly asks for an editing pass on an already-close deck, prefer one or two compact architecture anchors over a rewrite: a short boundary clarification, operational invariant, or implementation-proof tightening. Do not add product-promise/pitch pills unless he specifically asks for product or pitch framing. Then build, visually inspect the edited slides, and update the handovers.
- When Semyon says deck text feels unnatural, too punctuation-heavy, or “all over the place,” do a human-language pass on visible copy, not just layout polish: remove over-written semicolon-heavy phrasing, split dense clauses into natural sentences, prefer spoken project-walkthrough language, and keep slide titles audience-facing. Avoid meta titles such as “what I would say/talk through if asked” in the main deck; reword them as the actual presentation point, e.g. “What I’d harden next.”
- If Semyon asks for a middle ground between two deck variants, first identify the live project roots for each served port, then merge deliberately: keep the deck he says is more accepted as factual truth for all conflicting claims and visual system, while borrowing only the stronger story/context beats from the other deck. Do not average contradictory architecture claims.
- If Semyon says the deck is still worse than an older variant because it is “AWS diagram + complicated wording” or similar, do a story rescue instead of another diagram/fact pass: introduce the project plainly, name the product problems, then show the architecture as the answer. Preserve the trusted architecture facts, but make the visible flow “this is OghmaNotes → these problems appeared → we did this” before provider/runtime detail.
- When doing final visual polish, review slide states as rendered, not just final content. Avoid title-only first states and single-left-card layouts unless intentionally dramatic. For interview decks, make the core card group visible immediately and reserve `v-click` for takeaway lines, diagrams, code highlights, or optional details.
- When Semyon says slide text feels unnatural, over-written, too punctuation-heavy, or “all over the place,” do a visible-copy pass before adding more design. Prefer spoken, human phrasing; split semicolon-heavy sentences; remove internal scaffolding from visible titles/subtitles (`if asked`, `what I would talk through`, `optional`, `if there is time`); and make the close sound like an actual ending, e.g. `What I’d harden next` rather than a presenter prompt.
- For personal project decks, check pronoun consistency. Use `I` when the story is Semyon’s direct work/judgement; avoid vague `we` unless there really was a team or shared ownership.
- For back-pocket diagram slides, keep them in the deck when useful but do not label them `Optional:` visibly. Put time-permitting/if-needed guidance in speaker notes, and make the visible subtitle audience-facing rather than a presenter instruction.
- Center cover-page supporting elements when the title is centered: subtitle, badge/chip rows, and short framing lines should align with the title block rather than drifting left.
- When doing final visual polish, review slide states as rendered, not just final content. Avoid title-only first states and single-left-card layouts unless intentionally dramatic. For interview decks, make the core card group visible immediately and reserve `v-click` for takeaway lines, diagrams, code highlights, or optional details.
- When Semyon says slide text feels unnatural, over-written, too punctuation-heavy, or “all over the place,” do a visible-copy pass before adding more design. Prefer spoken, human phrasing; split semicolon-heavy sentences; remove internal scaffolding from visible titles/subtitles (`if asked`, `what I would talk through`, `optional`, `if there is time`); and make the close sound like an actual ending, e.g. `What I’d harden next` rather than a presenter prompt.
- For personal project decks, check pronoun consistency. Use `I` when the story is Semyon’s direct work/judgement; avoid vague `we` unless there really was a team or shared ownership.
- For back-pocket diagram slides, keep them in the deck when useful but do not label them `Optional:` visibly. Put time-permitting/if-needed guidance in speaker notes, and make the visible subtitle audience-facing rather than a presenter instruction.
- Center cover-page supporting elements when the title is centered: subtitle, badge/chip rows, and short framing lines should align with the title block rather than drifting left.
- For horizontal process flows, watch for cramped five-card rows. Prefer four clearer cards or a 3+2 layout; merge adjacent operational steps if that improves readability without harming the story.
- For diagram slides, add breathing room above the viewer/toolbar and keep optional full-system maps clearly optional if they are too dense to read at default zoom.
- For interview decks with presenter notes, make notes easy to jump in real time. Prefer repeated branch labels such as `QUICK`, `LOW-TIME`, `ANECDOTE`, `LONG`, and `ACCURACY GUARD` over scattered prose. Visible slides stay minimal; speaker notes carry optional background and casual stories.
- Check `package.json` scripts, but confirm CLI flags with `slidev --help` if serving remotely.
- Some Slidev versions use `--remote --bind 0.0.0.0` rather than `--host`.
- Put deck-wide CSS in `style.css` when possible; avoid making a final style-only slide in `slides.md`.
- For interview decks, keep visible slides concise and move talk tracks into Slidev presenter notes using HTML comments under each slide. Do not dump explanatory paragraphs into the visible slide body.
- If Semyon says a deck feels too interview/self-promotional, immediately reframe from career proof to architecture story: rename slides around systems/decisions (`System story`, `Current architecture`, `Ingestion decision`, `Worker claim detail`, `Release path`, `Reliability roadmap`) and remove `interview`, `STAR`, `pitch`, `hire`, and role/company-specific closing language from visible copy and notes unless explicitly requested.
- If Semyon asks whether the deck is fully accurate, do a repo-depth architecture audit before answering. Read the canonical repo and infra docs/code, then label every provider/runtime as retired/historical, current/live, or target/future/trial. Do not let a good-looking slide keep stale architecture claims.
- For migrated systems, verify queue/storage/vector/deploy claims from current runtime entrypoints and infrastructure docs, not from older diagrams. In Oghma specifically, current worker delivery is BullMQ/Redis + Node worker + Postgres status/recovery; `FOR UPDATE SKIP LOCKED` over `app.ingestion_jobs` is not the current primary queue proof.
- Keep code snippets short enough to fit on-screen. If a code slide clips, shorten the snippet first rather than shrinking everything into illegibility.
- Mermaid diagrams often need visual verification; simplify the graph and constrain SVG height if clipped.
- For rendered Mermaid/SVG diagrams, consider a custom fitted viewer plus padded SVG `viewBox`; verify with screenshots because exact-fit SVGs can still shave borders/text at the bottom or right.
- If SVGs are loaded through `<img>`, deck CSS cannot style inside the SVG. For dark decks, change the viewer frame background to deck tokens and either regenerate SVGs with dark/transparent theme variables or post-process SVG internals; avoid relying on CSS `filter: invert()` except as a quick emergency fallback because it can distort accents and labels. If using invert, remove root white backgrounds and only add narrow internal SVG overrides for cluster/label backgrounds — broad `text`, `marker`, `.actor`, or `.node path` overrides create artifacts.
- Keep appendix/back-pocket slide headings smaller than main narrative slide headings when diagrams are present; otherwise the heading eats the slide and forces diagrams into unreadable postage stamps.
- For presentation SVG viewers, avoid hidden interactivity unless explicitly needed. Wheel zoom/drag-pan with hidden reset controls feels broken in a live deck; prefer a static fitted image only when zoom is not needed. If Semyon asks for zoomable SVGs, restore them explicitly: small visible `− / 100% / +` controls, reset via the percentage button, bounded zoom such as `100% → 300%`, drag/pan only after zooming in, and wheel zoom only with a deliberate modifier key (`Alt`, `Ctrl`, or `Cmd`) so normal slide navigation is not disrupted. Do not add persistent cache-busting `?v=...` to SVG URLs unless debugging stale assets.
- For small card accent dots, prefer inline/flex heading markers (`h3::before` with `align-items: baseline`) over absolutely positioned card pseudo-elements; absolute dots often look out of line once fonts, padding, or card heights change.
- If a Slidev dev/background process reports `Port 3037 is already in use`, do not treat that as failure by itself. First check whether the existing server is already serving the current build, then decide whether a restart is needed.

## Handover docs

When the user asks for a handover or another agent will continue, create a project-local `HANDOVER.md` containing:

- current goal and audience
- files changed
- run/build commands
- server URL/port if relevant
- verification performed
- known warnings/blockers
- style/content constraints
- what to do next
- what not to touch

This is especially useful for multi-agent work where another agent may otherwise overwrite or duplicate changes.

## Pitfalls

- Do not over-style decks; “more polished” usually means clearer, shorter, and calmer.
- Do not treat “review”, “familiarise”, “look over”, or “give thoughts” as permission to edit. In review mode, read and critique only; offer concrete proposed changes separately.
- Do not inject pitch/product-promise framing into an architecture walkthrough unless Semyon asks for pitch shaping. His Oghma-style project decks should feel like a lived engineering walkthrough with anecdotes, not a sales narrative.
- Do not confuse current implementation proof with retired/prototype code. If the repo has both old and current worker/storage/vector paths, cite the current runtime entrypoint in the slide/notes and move historical code to an appendix or delete it.
- Do not overclaim observability. If the current system has logs, health checks, queue state, and manual inspection but not full SLIs/alerts, say that plainly and put alerting/p95/oldest-job-age work in the hardening slide.
- Do not treat cleanup as permission to remove useful affordances. If a deck relies on zoomable SVGs for architecture walkthrough/back-pocket detail, clean the behaviour rather than deleting zoom.
- Do not add gradients if Semyon has asked for no gradients.
- Do not rely on accessibility-tree text alone for visual deck QA; use a screenshot/visual check.
- For visual deck QA, use Antigravity CLI/Gemini as the eyes, not the lead author. Call `agy` headlessly (`-p`/`--print` style) on rendered slide screenshots and feed the dense visual handoff back to Claude/Fable/Codex for content/taste/implementation decisions. Do not create wrapper scripts unless Semyon explicitly asks; agents should call `agy` directly and choose the model/thinking level per task (`Gemini 3.5 Flash (Low)` for normal screenshots, Medium/High for dense UI, small text, diagrams, or multi-image comparison; Pro only when the visual extraction itself needs deeper reasoning).
- For make→view→iterate deck work, prefer Claude/Fable/Codex as the lead writer/implementer and Gemini/agy as screenshot critic. In a one-pass bakeoff, Gemini may produce visually better-fitting slides, while Claude tends to produce better copy/taste but can miss rendered layout failures; the best artifact comes from iterating with both roles separated.
- Do not dump a huge plan when the user wants live conversational preparation.
- Do not leave presentation slide titles in a backstage/interview-prep voice. If a title describes what Semyon would say “if asked,” rewrite it as the slide’s actual point for the audience.
- If visible deck copy starts to feel clever, compressed, or punctuation-heavy, simplify it until it sounds like something Semyon could say out loud without cringing; semicolons are usually a smell in this deck style.
- If Slidev/Shiki code looks dim after theme overrides, inspect visually and force `.slidev-code-wrapper .line { opacity: 1 !important; }` plus explicit code font size/line-height in `style.css`; build output alone will not catch low-contrast code.
