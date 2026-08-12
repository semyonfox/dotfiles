---
name: static-artifact-publishing
description: "Use when publish reviewable static pages, reports, galleries, and generated artifacts to temporary or lightweight hosting safely."
version: 1.0.0

metadata:
  harness: [hermes]
---

# Static Artifact Publishing

Use when the user asks to host, publish, share, deploy, or turn a working list, report, gallery, demo, diagram set, or generated HTML artifact into a temporary public link.

## Goal

Publish a real, reviewable static artifact while preserving a local source directory that can be revised with images, SVGs, and updated content. This is distinct from deploying an application or production storefront.

## Workflow

1. **Confirm publication intent.** Publishing creates an external link. A direct request to use the user's publishing service is authorization; otherwise prepare locally and ask before upload.
2. **Use approved inputs only.** If the user has selected/whitelisted ideas, filter to those selections rather than copying the whole brainstorm, including rejected items.
3. **Build a static-site directory.** Create a root directory containing `index.html` and any `assets/` subdirectory. Preserve this directory after publication so subsequent artwork can be added in place.
4. **Make it self-contained and portable.** Use relative asset URLs (`assets/design.svg`), semantic HTML, a clear page title, responsive layout, and a visible statement if the page is a working list rather than a final product.
5. **Preflight content and layout.** Scan generated text/assets for obvious credentials or private data. Serve locally, probe the root over HTTP, and inspect it in a browser at the relevant viewport. Fix clipping, unreadable contrast, broken asset paths, or accidental inclusion of unapproved content before uploading.
6. **Publish with the appropriate configured service.** Capture the returned URL or page ID. For Semyon's Seol service, accept a single `.html`/`.htm` file or a directory/ZIP whose root is `index.html`; preserve relative asset paths. Publish with:
   ```bash
   seol publish --quiet --title "Descriptive title" PATH
   ```
   Re-publishing the same canonical source path updates its stable URL; use `--new` only when a separate page is intended. Seol links are temporary public links, not permanent or private hosting.
7. **Verify the public artifact.** Open the exact returned URL and check title, content, and representative assets. A successful CLI command alone is not sufficient. When a user supplies an existing Seol page to read rather than asking for visual inspection, fetch that exact URL directly with a bounded shell request first; do not search for it or open a browser by default.
8. **For chart-and-matrix briefs, use a real chart renderer and source data—not manually positioned decorative SVG points.** Extract or obtain the actual numeric series before rendering; do not alter point positions merely to make labels fit, and do not infer a data point from an arbitrary nearby label/leader-line anchor. Use Chart.js, Plotly, or an equivalent renderer so the scales own the point placement; verify a representative point against the input values and visually inspect the full result.

   When the input is an SVG chart rather than a data export, recover its axis mapping only after verifying it is linear, then map **every named series/family** in the supplied chart before making a routing recommendation. Do not silently omit a family merely because the initial question singled out other variants—the omitted cheap tier can change the recommendation completely.

   Dense scatter plots frequently have label collisions even where every label remains present in DOM text. Default to tooltips plus a legend or concise key beneath the plot when no label preference was given. If the user explicitly wants labels visible without hover, render compact on-plot labels with leader lines and collision-aware offsets; abbreviate repeated product prefixes (for example, `Luna max`, not `GPT-5.6 Luna max`) to keep labels readable. Never move the data point itself merely to make its label fit; move only its annotation.

   **Compressed-scale rule:** if a linear full-range chart squeezes a meaningful low-cost family into a few pixels, do not keep stacking labels until it looks cursed. Keep one clean, unlabeled full-range chart for the overall relationship, then add separate, clearly titled zoom panels for the compressed family and the remaining tiers. Each zoom must retain a truthful linear scale for its stated range and carry the visible labels. Verify the plotted dataset names in every panel—not only rendered appearance—so a dataset-index/order mistake cannot put the wrong family in a zoom.

   **Adding a second benchmark dimension:** when the user supplies a later chart for another axis (for example execution time after a cost/capability view), recover a separate numeric dataset from that chart’s verified linear axes. Add a dedicated scatter plot and a compact time/value table rather than relabelling the existing chart or cramming a second metric into point labels. If score values differ between supplied chart snapshots, label them as separate runs and explicitly tell readers to compare values within each chart; never silently blend them into one assumed experiment.

   **User-facing chart preference:** when the user asks for “little labels,” labels must be directly visible on the rendered chart; hover may provide precision, but must not be required for model identification. Treat explicit negative visual feedback such as “cursed” as a request to simplify the chart structure, not to add further annotation tweaks.

   **Bounded comparison scope:** when the user narrows an existing comparison to named families (for example, “Luna, Sol and Terra only for now”), apply that boundary everywhere: plotted datasets, chart legends/tooltips, matrices, surrounding prose, and axis ranges. Do not add external comparators merely because the new source chart includes them. Before replacing the public page, scan the generated source for excluded provider/model names, then open the exact public URL and confirm the rendered content stays inside the requested scope.
9. **Seol requires contained HTML: inline browser code or use non-script assets.** Before publishing an interactive chart, bundle its JavaScript into the final `index.html`; Seol rejects external `<script src>` tags, including same-directory relative scripts. Test that the hosted page exposes the expected canvas/chart object after publication.

   **Static-chart delivery pitfall:** do not treat HTTP 200 for a relative image file as proof that Seol will render it inside the hosted review page. The page can be sandboxed such that otherwise-valid relative SVG/PNG `<img>` resources show as broken images. Perform a visual audit on the exact public URL. If the image is blocked while the local preview works, embed a compact, generated PNG as a `data:image/png;base64,...` URI in `index.html`; retain the normal source image and source-data files in the local canonical directory for regeneration. Re-open the public page and verify each chart has non-zero rendered/natural dimensions and is visibly legible.

   **Adding hover to a static rendered chart:** keep the original source-data rows in the page as compact inline JSON, then use a positioned transparent hit area and an inline tooltip rather than inventing values from image pixels. Map pointer position only across the real plot area (excluding a legend/margins), snap it to the nearest source row, and display exact values plus the source-derived top category. Make the chart focusable and support arrow keys/tap as an alternative to mouse hover. After publication, verify the inline readiness marker/object and trigger a representative `pointermove` in the hosted DOM; assert that the tooltip becomes visible and contains the expected source-row values. This proves actual hosted interactivity, not merely script presence.
10. **Set and verify an explicit temporary lifetime when the user gives one.** After `seol publish`, apply it with `seol expiry PAGE_ID 7d` (substituting the requested duration), then run `seol info PAGE_ID` and confirm the active status and remaining lifetime. Do not rely on Seol's default expiry.
10. **Iterate without breaking the review link when desired.** Keep the local directory as canonical. When the host supports replacement and the user wants a stable link, replace the existing page after preflight; otherwise publish a distinct review version.

## Artwork and SVG Iteration

When an approved-list page will later gain one SVG per selected item:

- Keep each item’s display text and asset path associated in a small source data file or explicit markup; do not rely on fragile page-position matching.
- Add SVGs as relative assets and give meaningful `alt` text or a text label alongside them.
- Use stable, readable filenames derived from a slug, e.g. `assets/sudo-touch-grass.svg`.
- Render one or two representative assets locally before bulk insertion, then visually review desktop and mobile density before publishing the full set.
- Never claim artwork exists because filenames or empty placeholders exist; inspect real rendered SVGs.

## Data-backed portfolio and activity reports

When publishing a GitHub/career activity summary, make the scope a first-class visible part of the artifact rather than treating an authenticated API result as automatically safe to publish:

1. Prefer a **public-only** report for an external Seol page. Enumerate repositories currently public through the API, then count authored commits on their default-branch history and PRs/issues authored by the account. This avoids leaking aggregate private-repository activity.
2. Label limitations directly on the page: default-branch history omits unmerged/non-default-branch commits, and the repository scan reflects the generation date.
3. Include a year-by-year table and a totals summary; call out the current partial year with its cutoff date.
4. Retain the source `data.json` (or equivalent) next to `index.html`, alongside the data-collection script where applicable, so the report can be regenerated rather than hand-edited.
5. Before publishing, run a basic secret/private-data scan over both the rendered HTML and data source, then visually inspect the table at desktop and mobile widths.

Do not label this kind of review-page report as a permanent public profile or as a complete GitHub contribution total unless the collection method actually supports that claim.

## Seol Notes

### Sensitive-data exports

For an artifact containing financial records, account identifiers, email metadata, health data, private-source material, or similarly sensitive personal information:

1. Treat Seol as **public temporary hosting**, never private storage. A generic request to “share” or “put it on Seol” is insufficient: identify the exposure and ask whether the user wants a redacted dashboard, a local-only build, or a deliberately full public export.
2. If the user explicitly selects the full export, state that choice in the handoff and put a prominent warning at the top of the page: anyone with the URL can view/download the data and must not forward it.
3. Include source files only when the user explicitly authorises their exposure. When including them, link them with relative URLs and verify every exact public download returns HTTP 200 after publication.
4. Run `seol info PAGE_ID` after publishing and report the actual active lifetime. Do not claim the link is access-controlled or confidential.
5. Retain the local canonical source directory, but stop a temporary local preview server after public verification.
6. For a financial-summary page, distinguish **dated account snapshots**, **known-cash subtotals**, **spending flows**, and **counterfactual opportunity-cost figures**. Do not label a subtotal as current net worth when accounts have different as-of dates or investment/debt data is absent. Never add inflation shortfall to an investment opportunity-cost comparison when the latter already incorporates the former; state the overlap prominently. Label tax-adjusted investment values as illustrations unless the underlying lot-level tax calculation was actually performed.
7. When the user supplies a portfolio screenshot to complete an initially partial review, transcribe the current account total, each visible holding, displayed units and app-return percentage. Reconcile the visible positions plus cash to the account total, label small display-rounding differences, and update the total only as a timestamped **known financial-assets snapshot**. Explain that app percentage changes are point-in-time display figures, not annualised returns or forecasts; keep market-risk investments separate from emergency/near-term house money.
8. **Establish the money-ownership model before interpreting spending or income.** A current-account export is a payment rail, not automatically a personal budget. Work only from confirmed context when labelling flows as `self`, family/parent pass-through, shared household, gifts, reimbursed society/club activity, investment transfers, or unknown. Do not call recurring money “business income”, “profit”, salary, or an annual run-rate merely because it passes through the account; confirm ownership, reimbursement status, seasonality, and associated costs first. Treat unpaid freelance/invoice amounts as receivables, never current assets.
9. **Use careful financial labels in the artifact.** Until pass-through flows are paired and excluded, call gross card activity “merchant-category payment throughput” or “transaction evidence”, not personal discretionary spending, burn rate, or a savings rate. Show parent support separately as a safety net rather than income or net worth. For reimbursed student-society activity, show both outflows and reimbursements as a net-neutral pass-through outside the personal budget.
10. **When corrections materially change interpretation, refactor—not merely append.** Give a private financial review an explicit top-level structure: (a) dated known-assets snapshot, (b) money-ownership/operating model, (c) current investments, (d) savings/cash context, (e) payment evidence and its limits, (f) concrete actions, then (g) raw source pack. Retain raw exports and source downloads for traceability, but collapse them below the decision-ready summary. Include a compact owner-first tagging scheme (`self`, parent pass-through, society pass-through, gift, shared household, reimbursed) plus a separate purpose tag for material transactions.
11. **Reconcile pass-throughs two-sided before excluding them.** Match payment-platform inflows to finance-system reimbursement records using reference IDs, dates, amounts, payees and descriptions; preserve a row-level mapping CSV alongside a short scope/caveat note. A balanced exported ledger supports excluding the matched flow from personal income/spend, but does **not** prove no real-world contribution: call out possible cash, unsubmitted-receipt, timing and source-coverage gaps. Do not infer ownership merely from a merchant label such as a university or society; state the certainty level.

### Unpublished article previews

For a blog/article draft, keep the canonical Markdown outside the production content collection and render a separate static review directory. The review page should visibly say it is unpublished, set `meta name="robots" content="noindex, nofollow"`, and avoid production-navigation or claims that it is live. Retain both the Markdown source and the preview generator/directory locally so editorial changes can be regenerated and republished without moving the draft into production.

- Accept a single HTML file or a directory/ZIP whose root contains `index.html`.
- Do not use root-relative asset paths: Seol pages live under random `/p/<id>/` prefixes.
- Verify `seol` is configured without printing its token or configuration.
- Use `seol replace <page-id> <directory>` only when retaining the same temporary link is intentional.

## Pitfalls

- Uploading Markdown rather than the reviewable HTML page the user asked to share.
- Publishing unchecked brainstorm items alongside approved ones.
- Calling a temporary review page a finished store, website, or permanent public surface.
- Skipping browser inspection and discovering only after publication that text clips or asset URLs break under the host prefix.
- Rebuilding a separate directory on every iteration, losing the simple path for inserting later SVGs.

## Verification Checklist

- [ ] Root `index.html` exists
- [ ] No obvious secret/private-data match in generated text
- [ ] Assets are relative and resolve locally
- [ ] Local HTTP probe succeeds
- [ ] Browser review finds no material clipping/readability problem
- [ ] Returned public URL was opened and checked
- [ ] Local source directory is retained for the next iteration
