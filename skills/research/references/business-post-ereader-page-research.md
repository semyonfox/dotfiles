# Business Post e-reader page research

Use this when Semyon asks for exact Business Post print-page locations, adverts, coupons/stamps/codes, or date/page provenance.

## Key source

Business Post e-reader library:

- Library: `https://ereader.businesspost.ie/`
- Edition URLs look like: `https://ereader.businesspost.ie/e-reader/edition-2327/index.html`
- Page images are stored under the edition at:
  `files/assets/common/page-html5-substrates/page0009_4.jpg`

## Workflow

1. Open the e-reader library and list edition links. The page title/link text usually gives the section and issue date, e.g. `News July 5 2026`, `Property July 5 2026`, `Life&Luxury July 5 2026`.
2. Inspect anchor hrefs for exact edition IDs; browser console can extract them:
   ```js
   [...document.querySelectorAll('a')].map(a => ({ text: a.textContent.trim(), href: a.href }))
   ```
3. For an edition, fetch page images directly. Use a normal browser UA and set `Referer` to the edition index URL; without referer, image requests may return 200 with empty content.
4. Probe page files sequentially until an empty response:
   ```text
   https://ereader.businesspost.ie/e-reader/edition-<ID>/files/assets/common/page-html5-substrates/page0001_1.jpg
   ```
   Suffixes are quality levels. `_1` is low-res; `_4` is much higher resolution and better for reading small advert/code text.
5. Build a contact sheet of thumbnails across pages to visually locate the relevant advert/code first, then inspect the individual high-res page crop.
6. Cross-check with any official landing page such as `https://www.businesspost.ie/win` for rules, dates, and prize mechanics, but use the e-reader page image for exact paper section/page provenance.

## Notes from the July 2026 Summer Prize Hunt session

- The official competition page redirected to `https://competitions.businesspost.ie/summer-prize-hunt-2026/`.
- It stated codes appear in the Business Post print edition every Sunday from 5 July to 9 August 2026.
- First confirmed code circle was in `News July 5 2026`, edition `2327`, page 9.
- The high-res page image `page0009_4.jpg` made the first code readable as `5th JULY SU26`.
- Property and Life&Luxury supplements for the same date did not contain the code/ad in that session.

## Pitfalls

- Search engines may not index these e-reader pages or may only find the landing page. Go to the e-reader directly.
- `web_extract` may only return the unsupported-browser placeholder for edition pages; fetch the HTML/assets directly instead.
- A successful HTTP 200 with zero-byte image content usually means missing/insufficient request headers, especially `Referer`.
- Do not claim future issue page numbers before the e-reader issue exists. Give confirmed page/date results and clearly mark future scheduled dates as not yet verifiable.
