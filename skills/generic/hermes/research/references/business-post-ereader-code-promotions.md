# Business Post e-reader code/coupon promotion workflow

Use when a user asks for Business Post print-only stamps, coupons, codes, page numbers, or competition adverts that may not be indexed as normal articles.

## Fast path

1. Check the competition landing page first. `https://www.businesspost.ie/win` may redirect to a competitions subdomain and often contains the official dates, mechanics, prize terms, and minimum-code rules.
2. Use the e-reader library: `https://ereader.businesspost.ie/`.
3. Inspect the relevant Sunday editions. Prioritise the main **News** edition first, then **Property**, then **Life&Luxury** if the code is not found.
4. E-reader edition links look like:
   `https://ereader.businesspost.ie/e-reader/edition-####/index.html`
5. The HTML exposes page images even when extraction says the browser/device is unsupported. Page images are usually at:
   `files/assets/common/page-html5-substrates/page0001_1.jpg` through `page00NN_1.jpg` for thumbnails and `_4.jpg` for high-res.
6. Download/check pages with the edition page as the Referer. A zero-byte JPEG response generally means that page/scale does not exist; retry with the right suffix (`_1`, `_2`, `_3`, `_4`) before giving up.
7. Make contact sheets from thumbnails for quick visual scanning, then crop high-res pages for the exact code/circle text.
8. Report the **date, section, page number, code text, and confidence**. If the code is unreadable, attach or describe the crop instead of guessing.

## Known example from Summer Prize Hunt 2026

Official page: `https://www.businesspost.ie/win` → `https://competitions.businesspost.ie/summer-prize-hunt-2026/`

Mechanics:
- Unique coloured code circle in the Business Post print edition each Sunday from 5 July to 9 August 2026.
- Minimum 4 of 6 valid codes = one prize draw entry.
- All 6 valid codes = bonus entry, so more codes are better if easy to collect.
- Entry form appears in Weeks 4 and 6.

First code found:
- 5 July 2026, **News**, page **9**, code **SU26**.

## Pitfalls

- Do not assume the code is in the Life & Luxury/travel section because the prize is a weekend away; the first observed code was in main News.
- Do not stop at web search. These promotions can be visible only in the print replica/e-reader images.
- Do not rely on page extraction of the edition HTML; it may return only the unsupported-browser message. Inspect linked assets instead.
- When scheduling follow-up cron jobs, include known edition/page/code context and the official collection dates so the future job does not repeat broad search work.
