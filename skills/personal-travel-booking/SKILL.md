---
name: personal-travel-booking
description: "Use when book and optimise personal rail, bus, flight, and local travel for Semyon, while handling accounts, fares, seats, payment approval, and delivery safely."
version: 1.1.0
created_by: agent

metadata:
  harness: [hermes]
---

# Personal Travel Booking

Use for Semyon's personal transport journeys, especially bookings that require a logged-in account, a student fare, seat choice, payment, or a timed reminder.

## Default travel preferences

- For rail trips into Galway, departure station is **Athenry**.
- Select a **student / Young Adult fare** whenever Semyon is eligible; verify any required ID or Leap card condition before purchase.
- Optimise practical arrival, not only timetable compliance: account for walking from the station and a small delay buffer.
- Prefer a QR/e-ticket sent to the account email unless Semyon requests collection or a physical ticket.

## Conference and event-trip budgeting

For conference travel, separate costs before presenting a recommendation: **admission**, transport, nights, local transit, food, and optional spending. Never let an all-in number obscure that a commercial conference ticket alone may be hundreds of euro.

- Establish the user's actual ticket and all-in budget early. A student asking about an event may reasonably mean a €50–€150 walk-in/student/early-bird price, not a corporate-priced €600+ pass.
- Before recommending an expensive standard pass, actively check official student, young-professional/talent, volunteer, scholarship, university/partner, speaker, startup, financial-assistance, and early-bird routes. State eligibility requirements precisely; do not call a startup or volunteer rate a general student discount.
- Give a blunt fit verdict as well as price. For a student choosing one trip, rank technical/career value, networking value, and holiday value separately rather than letting event prestige decide.
- If the user asks to choose between expensive events, give the direct conditional answer first (for example, paid general-admission route versus a volunteer route), then the lower-cost alternatives. Do not turn a budget-constrained decision into a long generic itinerary before confirming the ticket route is realistic.
- Planning estimates must be labelled as estimates rather than live held fares. Include the trip length assumed and whether the total excludes positioning travel, meals, luggage, insurance, and incidental spending.
- For a multi-day conference where networking and evening events matter, recommend an itinerary that arrives the day before the first likely on-site commitment and returns no earlier than the day after the final conference evening. Do not optimise away the opening night, official evening programme, or plausible late-night networking merely to save one hotel night.
- If the current-year agenda is not published, inspect the official schedule page and prior-year timetable to identify only the **structural** commitments worth protecting (for example, an opening-night pattern). Label prior-year timings as non-confirmed; never turn them into a claimed current timetable. Check official Night Summit/meetup pages separately: events described as attendee-ticket benefits are not speculative “unofficial afters”.
- When a live aggregator is blocked or a carrier’s unauthenticated availability response is unusable, say that no verified fare has been obtained. Preserve the recommended direct-route/date shape and continue only through a usable live booking surface; never manufacture a price or call an itinerary bookable.

## Safe booking workflow

1. Confirm journey: origin, destination, date, service, passenger type, and one-way/return. For a timetable-only question that omits a date, use the current local time in the traveller’s timezone to select the practical next travel date (for example, tomorrow after the morning has already passed), and state that date explicitly rather than silently assuming it. Re-check and resolve the live local date whenever a follow-up changes a relative-day instruction (for example, from “tomorrow” to “today”); never carry the prior calendar date forward.
2. Check live operator availability and price. Treat third-party timetables as discovery only; use the operator booking flow for the final facts. For a timetable-only Irish regional journey, prefer the operator’s live route-page table for the applicable day type over a downloadable timetable PDF when they differ: PDFs can remain hosted after their stated effective date. Preserve the stop-to-stop pairing by matching the same service column, rather than independently listing every departure and arrival on the route.
   - For an accommodation price check, confirm the search UI visibly retains the **check-in date, check-out date, guest count, and currency** after submitting. A destination-results page or a generic “from” price is not evidence for “tonight.”
   - If occupancy was not specified, use the site’s displayed default only as a clearly labelled comparison (for example, “1 night, 2 adults”), not as an unqualified room or per-person quote. Do not answer a later “1 adult” follow-up by halving or loosely re-labelling a two-adult rate: re-run and verify the one-adult search, or plainly give only a market estimate. Report the currency actually displayed; convert only with a currently verified exchange rate.
   - Give a fast answer first: a realistic range and the two or three closest suitable options, then flag only material uncertainty such as taxes, cancellation terms, or an unconfirmed date filter.
### Flight-comparison deliverable

When Semyon asks to “get specifics”, “decide what’s best”, or compare airports, do not stop at a route recommendation. Before calling the comparison complete, present a concrete ranked shortlist with: exact outbound and return times/dates, carrier, stop pattern, baggage basis, total displayed fare, and booking source.

- Do not treat generic route pages, search-result snippets, historical “from” prices, or an assumed timetable as a live fare card.
- Keep each fare internally consistent: a displayed return fare may use a different outbound/return pairing than the individual flights being recommended. Never attach a round-trip price to a hand-picked pair unless the live booking result explicitly confirms that exact pairing and total.
- If luggage matters, compare **luggage-inclusive checkout totals**, not bare fares. State the requested bag (for example, a 20 kg checked bag) and cabin item; do not estimate a dynamic add-on or imply the price gap has narrowed without reading the live operator checkout.
- Do not recommend a carrier for vague “comfort” or service-quality claims on a short-haul economy route. Ground the decision in the chosen timetable, fare rules, confirmed bag allowance/total, disruption options when known, and the user’s actual trip shape.
- Give the decisive recommendation first once the evidence exists: carrier, exact flights, bag setup, and a clearly labelled total. Avoid repeated progress updates or switching recommendations as partial fare fragments arrive.
- Choose the winning airport/flight first, then price accommodation around the selected itinerary. Do not present accommodation candidates as a completed recommendation if the flight decision is still unverified.
- A price-led accommodation candidate must show the retained dates, occupancy, currency, bed/room type, cancellation terms, and final stay total. A nightly “from” rate can be an initial lead only, never a total-trip comparison.
- If no live fare can be read after a practical fallback through another usable operator/aggregator surface, state once that the requested comparison is incomplete. Do not issue repeated progress updates, imply that a best flight has been identified, or call the task done.

### Google Flights resilient live-fare fallback

When ordinary airline or aggregator pages are challenge-gated but live discovery is still needed, a Google Flights structured query can be a practical **comparison** fallback. Build a query for each requested leg with explicit date, airport codes, passenger count, currency, cabin, and `max_stops=0`; use a current Windows Chrome client identity and complete the ordinary Google consent flow before parsing the returned result data. This can provide live airline, directness, departure/arrival time, duration, aircraft, and displayed fare data even when the normal visual search page does not render cards.

- Query the outbound and return **as separate one-way searches** when extracting a shortlist. Some parsers surface only the outbound card for a round-trip query, so its price must not be labelled a verified round-trip total unless the result structure explicitly contains both legs and the total.
- Treat an empty direct-only result for an airport/date as “no non-stop option returned,” not proof that the airport has no conceivable route. State the applied direct-flight filter.
- Use the result as a live comparison source, then open the selected carrier’s booking flow before claiming a final purchasable fare, bag allowance, cancellation terms, or seat-selection conditions. Do not blend a generic airline baggage rule into a fare card without verifying the selected fare bundle.
- For a low-cost-versus-full-service comparison, do not compare only the headline cheapest pair. Price a practical alternative on the low-cost carrier that preserves the traveller’s stated schedule, then separate the true upgrade premium from the price of an inconvenient dawn/late leg. Describe the real comfort differences candidly: short-haul economy is not a premium cabin, and luggage, priority, flexibility, and timing can matter more than aircraft branding.
- If an anti-bot or consent barrier appears, do not bypass it. A standards-compliant browser identity is appropriate only when the user explicitly asks for normal browser-style access; complete ordinary consent where offered and stop for any human challenge that requires the traveller.

3. For a seat preference, inspect the **actual seat map**. Do not infer coach orientation solely from coach letters: formations and platform working can vary.
4. If the map cannot establish the requested direction/end, state that uncertainty. Choose the nearest available coach/end only when Semyon has authorised a best-effort choice.
5. Establish and verify the operator account session **before** rebuilding a journey or implying that checkout can continue. If the current browser is anonymous or loses the authenticated session, say so plainly and do not claim a booking is in progress.
6. Log in only through an account credential source explicitly authorised by Semyon. Prefer password-manager UI/autofill or a secure authenticated browser surface. Never ask them to paste a master password, and never place credentials, card numbers, CVVs, or session tokens in a URL, browser console, script, shell history, or final response.
7. Review fare, passenger category, seat, ticket fulfilment, and final amount before payment.
8. A direct instruction to make the booking authorises purchase at the verified amount, but respect bank 3-D Secure: ask Semyon to approve the in-app bank prompt and never attempt to bypass it.
9. Do not say a ticket is “ready for payment” or ask for bank approval unless the live, current checkout actually displays the operator payment step or bank authorisation request. Verify the confirmation page or booking reference before claiming success. Give the user the booking reference and where the QR ticket will arrive, not sensitive payment data.
10. Lock the password vault promptly after credentials have been retrieved, if Semyon requested it.

## Interrupted checkout and progress reporting

- A declined/abandoned 3-D Secure or bank-authorisation attempt may invalidate the operator checkout. Treat it as a new transaction: re-check account login, live availability, student/YA category, fare, seat selection, and final total before sending another payment request.
- Do not infer that a previously selected seat or fare is still held after a rejected payment.
- Make progress with the live booking flow before reporting it. Do not send “I’ll recreate it” / “I’ll keep going” status-only messages; either continue the flow in the same turn or report the concrete blocker and the safe hand-off.

## Vault-session handling

- A `BW_SESSION` token is sensitive. Never print, repeat, store, or include it in a file, URL, browser console, or command line that can be captured in history/logs. Prefer vault UI/autofill; if a secure runtime integration is unavailable, pause rather than extract credentials into an unsafe path.
- A vault lock invalidates the active CLI session for practical use. If another booking is needed afterward, re-establish access through a fresh, secure unlock flow rather than trying to reuse an expired session.
- The browser used by the agent may not share Semyon's normal-browser autofill state. **Before promising that a fresh vault unlock will let the agent resume a booking**, verify all three live prerequisites: the operator account is signed in, the agent can access the vault without exposing secrets, and there is a secure browser/autofill bridge. A missing prerequisite is a blocker, not a reason to claim checkout is being rebuilt.
- Never report a bank authorisation request, a payment-ready basket, a selected seat, or a restarted checkout from remembered state. Each such status must be visible in the current operator browser session immediately before it is reported.
- If the secure bridge is absent, explain that once with the exact safe hand-off. Do not repeatedly invite more session tokens or imply that accepting credential-logging risk changes the boundary.

## Irish Rail notes

- For a timetable question with a concrete cutoff (for example, “up to noon”), query the operator planner for **All day** on the explicit date, then filter the displayed direct services by the relevant departure or arrival cutoff. Do not assume a preset time band (such as “Before 10AM”) gives the complete set around the boundary; it can return a differently shaped result list.
- The Irish Rail booking flow can offer Student fares under **YA / Student** and displays an eligibility warning; accept only where Semyon has indicated eligibility.
- Seat selection comes before extras, personal details, and payment. There may be an automatic-seat option and a manual coach/seat map.
- Galway Ceannt is a terminus for Dublin services. The live map did not label the Galway-facing coach end in the observed flow, so coach letters alone are not a guarantee. See `references/irish-rail-seat-and-payment-flow.md`.

## Completion checklist

- [ ] Correct service/date/origin/destination
- [ ] Correct passenger fare category
- [ ] Seat preference followed or uncertainty disclosed
- [ ] Final price verified
- [ ] 3-D Secure approval completed if required
- [ ] Booking confirmation/reference captured
- [ ] Ticket delivery route confirmed
- [ ] Vault locked if used
