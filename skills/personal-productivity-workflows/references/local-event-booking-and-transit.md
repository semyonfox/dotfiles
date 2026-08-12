# Local event booking recap and transit handoff

Use this reference when Semyon asks for details of events already booked/signed up for, especially PorterShed/Galway events, and wants practical travel details.

## Core workflow

1. **Reconstruct the booking**
   - If the booking was made in a previous turn/session, use session search before asking Semyon to repeat himself.
   - Capture: event title, date, start/end time, venue, booking confirmation/reference, email alias used if relevant, and any required demographic/sign-up choices.
   - Do not expose private email details unless helpful; usually `+portershed Gmail alias` is enough in a chat recap.

2. **Verify with official sources**
   - Prefer the venue/event official page over web-search snippets.
   - For PorterShed, the event index is usually `https://portershed.com/events/` and individual booking pages often live under `https://portershed.clr.events/event/...`.
   - ClearBookings pages can be JS-heavy; if `web_extract` returns little/no content, use browser snapshots. The accessible tree often exposes the event description, venue, session time, ticket/free status, and registration fields.
   - Use local news only as a cross-check when it adds details not visible on the official page.

3. **Give a compact handoff**
   - Title + time + venue/address.
   - One-line value/context: why the event is worth going to.
   - Booking reference if known.
   - Official link.
   - Travel recommendation with buffer.

## PorterShed specifics learned

- PorterShed a Dó is at/near **15 Market St, Galway**.
- PorterShed pages may show “PorterShed a Dó” or just “PorterShed”; verify event body for the exact venue string.
- Event registration may only require first name/surname/email for some events; optional demographic fields can appear depending on the event.
- Semyon’s signup-form preference belongs in user memory, but for this workflow: avoid optional sensitive demographic fields by default; if required, use the stored preference.

## Irish Rail realtime pattern

For Athenry departures, Irish Rail exposes station realtime XML without auth:

```text
https://api.irishrail.ie/realtime/realtime.asmx/getStationDataByNameXML?StationDesc=Athenry
```

Useful fields:

- `Destination` / `Direction` — filter for Galway-bound services.
- `Expdepart` — expected departure at Athenry.
- `Destinationtime` — arrival at final destination; for Galway-bound trains this is Galway Ceannt.
- `Late`, `Status`, `Lastlocation` — sanity check if running late/en route.

When multiple trains work, recommend the one that arrives with a comfortable walking buffer. For a noon PorterShed event, a train arriving Galway Ceannt around 11:10 is better than one arriving 11:50 even if both are technically possible.

## Walking / map handoff

Use the maps script from this skill for station-to-venue distance:

```bash
MAPS="$HOME/.hermes/skills/productivity/personal-productivity-workflows/scripts/maps_client.py"
python3 "$MAPS" distance "Galway Ceannt Station" --to "PorterShed a Dó, Galway" --mode walking
```

The OSRM walking duration can be unrealistically optimistic; present it as “short walk / give yourself about 10 minutes” rather than parroting a too-precise 4.54 minutes.

## Tone/format for Semyon

- Be terse and practical: “take this train, here are the event refs”.
- Lead with the actionable travel choice, not the whole timetable.
- Include backup options only when useful.
- Avoid overexplaining how the booking was found unless there was uncertainty.
