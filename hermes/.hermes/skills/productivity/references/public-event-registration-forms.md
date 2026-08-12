# Public event registration forms

Use this when booking Semyon into public/local events such as PorterShed, meetup, university, community, or conference sessions.

## Defaults for Semyon

- Use known identity details when the user has authorized signup and the fields are ordinary contact fields.
- For Gmail filtering, use a clear service-specific plus-address when requested, e.g. `semyon.fox+portershed@gmail.com` for PorterShed bookings.
- Prefer privacy for optional sensitive demographic/diversity questions: skip them or choose `Prefer not to say` unless Semyon has explicitly specified an answer for that form.
- If a field is required and cannot be skipped, current defaults are: gender `male`; disability `no`; student status can be answered honestly when relevant.
- Do not treat suspected/undiagnosed ADHD or autism as a disability-form answer unless Semyon explicitly says to for that specific form.

## Browser workflow

1. Open the event page and capture exact title, date/time, venue, price, and organiser.
2. Fill attendee/contact fields with the user's authorized details.
3. If plus-addressing was requested, choose a service/event-family tag that will remain useful for filters.
4. Handle optional fields conservatively; report what was chosen.
5. Dismiss cookie overlays before relying on clicks.
6. If a visible click does not advance, inspect inputs/buttons with `browser_console`: Angular/Material forms may use hidden backing inputs behind radio groups.
7. Confirm submission only after reaching a thank-you/confirmation page or receiving a confirmation number/email notice.

## User-facing report

Report concisely:

- Event name
- Date/time and location
- Email/alias used
- Confirmation number or booking reference
- Optional demographic answers chosen, if any
- Anything still needing the user's action, e.g. check confirmation email/spam

Never claim the user is registered merely because the form was filled or the submit button was clicked.
