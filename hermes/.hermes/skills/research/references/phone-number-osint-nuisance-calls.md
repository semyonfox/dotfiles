# Phone-number OSINT for nuisance misdirected calls

Use when a user is receiving repeated wrong-number calls and wants to know where a phone number is exposed.

## Goal
Find whether the number appears in public web listings, spam/scam databases, accommodation/travel listings, or typo-nearby business listings — without over-collecting private identity data.

## Practical query set
For an Irish number like `+353 87 123 4567`, search exact and normalized forms:

- `"+353 87 123 4567"`
- `"+353871234567"`
- `"0871234567"`
- `"087 123 4567"`
- `"087-123-4567"`
- `"00353 87 123 4567"`
- `"00353871234567"`
- last 7-9 digits in quotes for formatting/typo cases

Then add context terms:

- `hotel`, `B&B`, `BnB`, `accommodation`, `late checkout`, `booking`, `check out`
- `spam`, `scam`, `who called me`, `nuisance`
- site scopes: `site:booking.com`, `site:airbnb.*`, `site:tripadvisor.*`, `site:google.com`, `site:facebook.com`

## What to inspect
- Exact public hits first.
- Near misses: same prefix + swapped/missing digits, especially hospitality businesses whose callers could misdial.
- Spam/caller-report pages, but treat them as weak signals unless the exact number has reports.
- Platform pages may hide contact details behind apps, dashboards, booking confirmations, or anti-indexing; absence from search does not prove absence from the platform.

## Recommended user-side evidence collection
The fastest source is often the callers themselves. Ask the affected person to answer a few calls and ask:

> Sorry, wrong number. Can you tell me where you found this number — Google, Booking.com, Airbnb, a website, confirmation email/text, or the hotel directly?

Log caller-reported source, business name, and screenshot/URL if available. If it points to Google Business, Booking, Airbnb, TripAdvisor, etc., use that platform's correction/report channel with a screenshot and state: private number, not associated with the business.

## Immediate mitigation
- Voicemail: “If you’re calling about hotel/BnB/booking/late checkout, wrong number; this is a private mobile.”
- Enable unknown-caller silencing / spam screening temporarily.
- If an exact public listing is found, preserve screenshots before requesting correction.

## Cautions
- Do not publish or amplify the private number in new public reports unless the user explicitly wants to report it.
- Avoid paid people-search sites unless the task explicitly needs owner identity; for misdirected calls, exposure/source matters more than personal attribution.
- Do not conclude “scam” just because calls are numerous. Repeated hospitality-specific calls often mean a misconfigured/private listing rather than malicious activity.
