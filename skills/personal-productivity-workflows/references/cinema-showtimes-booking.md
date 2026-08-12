# Cinema showtimes and booking workflow

Use this when Semyon asks what is on locally, compares film options, or wants help getting to the ticket-payment handoff.

## Source order

1. Check official cinema sites first for current showtimes and booking links.
   - Eye Cinema Galway pages expose showtime links to Veezi (`ticketing.eu.veezi.com/purchase/...`).
   - Omniplex pages expose screen/time/cost directly in the page accessibility tree.
   - IMC pages and entertainment.ie are useful cross-checks when official pages are clunky.
2. Use entertainment.ie as a broad aggregator and cross-check, not the only source for final booking links.
3. For Irish age ratings and reasons, use IFCO title pages when available; they include classification and content rationale.

## Output shape that works well

- Lead with the requested film and times, not every nearby cinema.
- Include venue/location, start time, format, and known price when available.
- Exclude explicitly unwanted films from recommendations, but mention only if needed.
- For rating questions, give a compact table: film, IFCO rating, one-line blurb, why the rating.

## Booking handoff process

Do not enter payment/card details. Help up to the payment step, then hand off.

Before opening/finalizing a booking, ask/collect:

1. Showing time.
2. Ticket mix (adult/student/teen/child/senior) and count.
3. Seat preference.
4. Whether they want online guaranteed seats or to risk walk-up box office purchase.

If the ticketing page is protected by Cloudflare/bot checks, do not fight it. Extract/show the direct showtime purchase links from the cinema page and explain the user should open the link directly on their device.

For online booking, assume payment is required online unless the booking flow clearly offers reserve/pay-later. Mention that walk-up box office payment is likely possible but not seat-guaranteed.

## Seat guidance

For best general cinema sound/picture:

- Pick three adjacent seats in the centre block if possible.
- Aim horizontally centred and roughly two-thirds back from the screen, or just behind the room midpoint.
- Avoid front rows and the back wall unless the auditorium is nearly full.
- If multiple people, preserve togetherness over perfect acoustic position.

## Eye Cinema Galway notes from prior session

- Supergirl (Fri 3 Jul 2026) had direct Veezi links per showing from Eye's page:
  - 16:00: `https://ticketing.eu.veezi.com/purchase/106507?siteToken=e0prtsa260ab0513nxwebdgsy0`
  - 18:25: `https://ticketing.eu.veezi.com/purchase/106508?siteToken=e0prtsa260ab0513nxwebdgsy0`
  - 20:45: `https://ticketing.eu.veezi.com/purchase/106565?siteToken=e0prtsa260ab0513nxwebdgsy0`
- These links are session/date specific; use the method, not stale links, for future bookings.
- Ticket prices found on Eye's ticket-prices page for standard 2D afternoon/evening: adult €12, student €7.50 with valid 3rd-level ID, teen €9.50. Re-check before quoting in future.