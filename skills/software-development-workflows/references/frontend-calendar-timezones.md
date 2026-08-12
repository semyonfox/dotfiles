# Frontend calendar/timezone boundary checks

Use this when reviewing calendar, scheduling, or date-range PRs in browser/Next apps.

## Standard model

- Store and query instants as UTC ISO strings / database `timestamptz`.
- Render and group records by the user's intended local calendar date.
- When fetching a visible local date range, construct the local wall-clock boundary first, then convert that boundary to an ISO instant.
- Backend range queries should use overlap logic, not strict containment, for scheduled blocks: `starts_at < end AND ends_at > start`.

## Native JavaScript approach

For browser-local calendars with no timezone library, constructing local boundaries with the numeric `Date` constructor is acceptable and DST-aware for the user's local timezone:

```ts
const start = new Date(year, monthIndex, day, 0, 0, 0, 0).toISOString();
const end = new Date(year, monthIndex, day, 23, 59, 59, 999).toISOString();
```

Avoid appending `T00:00:00Z` or `T23:59:59Z` to a local date key unless the UI is explicitly UTC-based. That treats local dates as UTC dates and can miss/misplace blocks around midnight and DST transitions.

## Review checklist

- Check whether the app already uses a date/time library before adding one.
- Confirm whether the date range is user-local, institution-local, or fixed timezone.
- Add DST transition tests for the target timezone when changing local date boundaries.
- Preserve overfetching buffers intentionally used by month views unless the PR is explicitly tightening them; consolidate the conversion helper without narrowing the actual fetch window.
- Prefer shared helpers for date-key formatting and local-range-to-ISO conversion across week/month views so fixes do not diverge.
- Check both initial fetch and refresh/event-driven fetch paths; they often duplicate date-range construction.
