# Sticker / concept design boards

Use this when a selected Markdown checklist needs to become a temporary static page for review and later visual-artwork iteration.

## Reliable pattern

1. Treat the checked Markdown items as the source of truth.
2. Render only selected entries, grouped by their original collection/section.
3. Make one card per selected idea.
4. When artwork is pending, put an empty dashed SVG frame immediately beneath the card title. Use a fixed viewBox/aspect ratio and an accessible name such as `Empty SVG artwork frame for <idea>`.
5. Put the total selected count in the header. Verify `selected == cards == SVG frames` before publishing.
6. Open the locally served page at desktop width; check long titles, wrapping, frame presence, visual hierarchy, and accidental literal Markdown syntax such as asterisks.
7. Scan generated content for credentials before publishing.
8. Publish a static root containing `index.html`. Retain the page ID; update with `seol replace PAGE_ID PATH` rather than making a new link for every pass. Re-open the hosted URL to verify the replacement.

## Copy interpretation

Technical-looking copy may be the joke, not an operational request. In a sticker conversation, `Check Out My New Website: localhost:80` should be treated as literal sticker text unless the user explicitly asks to troubleshoot a site.

## Do not

- Do not invent finished art inside a placeholder frame.
- Do not publish unchecked/rejected ideas just because they were present in the source brainstorm.
- Do not let the static board become a hand-maintained divergent list.
- Do not report success based on the upload output alone; verify the public page.
