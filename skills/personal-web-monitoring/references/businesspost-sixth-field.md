# Business Post sixth-field form watcher (example)

## Situation

On 9 August 2026, the official Summer Prize Hunt page stated that six collected codes earned a bonus entry, but the live online form exposed only five labelled fields: `Week 1 code` through `Week 5 code`.

Official page:

`https://competitions.businesspost.ie/summer-prize-hunt-2026/`

## Reliable condition

Alert only when the returned form HTML contains a specific `Week 6 code` (or equivalent) field label. Do not treat prose about “six codes” as a trigger.

## Implementation pattern

- Fetch with a short timeout and a basic User-Agent.
- Regex-match the field label case-insensitively.
- On first true match, create `~/.hermes/state/<watch>.notified` and print the alert.
- On later matches or any non-match, print nothing.
- Use a script-only (`no_agent=true`) cron task so empty stdout produces no delivery.

## External-action boundary

The monitor must never fill the new field, tick a consent checkbox, or submit the entry. It only reports that the condition is now present.
