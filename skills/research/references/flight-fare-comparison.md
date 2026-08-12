# Flight fare comparison notes

Use this when comparing airfare across airlines or aggregators.

## Working pattern
- Start from the exact itinerary and dates the user cares about.
- Prefer live booking/aggregator pages over memory or static snippets.
- Compare at least one direct carrier source plus one aggregator if possible.
- Treat prices as approximate: baggage, seats, flexibility, and currency/locale can change totals.

## Useful fallback order
1. Airline booking flow for the exact route/dates.
2. Aggregator search page that renders visible results in the browser.
3. Another aggregator if the first one blocks or omits carriers.

## Practical browser notes
- Some pages only become usable after consent/cookie handling in a real browser context.
- Querying fare endpoints directly can fail unless the browser context has already established the session.
- If a search page loads but the content is empty or errors, inspect visible page text before assuming the search failed.

## Search-site quirks observed
- Google Flights may load but still return a generic error for some itineraries.
- Skyscanner can stop with a bot/captcha challenge.
- Kiwi can expose usable route results and price bands even when direct airline probing is awkward.
- Carrier filters may exist but still return "no airlines to choose from" for a supposedly valid filter state.

## Extraction hints
- For route pages, capture the live best/cheapest/fastest price bands first.
- Then inspect visible result cards for the actual carrier(s), stopovers, and duration.
- When comparing cabins, keep economy vs business totals separate and note the delta.
