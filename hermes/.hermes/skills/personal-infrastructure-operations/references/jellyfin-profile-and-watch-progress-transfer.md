# Jellyfin profile creation and watch-progress transfer

Use for explicitly requested household-profile setup and scoped watch-state moves. Treat user progress as private data: inspect exact users and the exact title before mutation, and do not expose API keys/tokens.

## Profiles

1. Discover the running `jellyfin` container and config mount with `docker inspect`.
2. Retrieve an existing API token privately from Jellyfin's SQLite `ApiKeys.AccessToken` only for local API calls; never print it.
3. `GET http://127.0.0.1:8096/Users` with `X-Emby-Token` to find a case-insensitive existing profile and inspect `HasPassword`/`HasConfiguredPassword`.
4. Create a missing passwordless profile through the local API:

```http
POST /Users/New
Content-Type: application/json
X-Emby-Token: <private token>

{"Name":"michelle","Password":""}
```

The endpoint requires a non-empty JSON body; query-only or form requests are rejected. Re-read `/Users` and require exactly one lowercase profile with both password flags false.

## Transfer progress for one series

Jellyfin may show a clean canonical series ID through the API while its SQLite IDs are hyphenated UUIDs. Compare using a normalized form such as `lower(replace(Id, '-', ''))`.

1. Resolve the exact series through `GET /Users/{polinaId}/Items` with `SearchTerm`, `IncludeItemTypes=Series`, `Recursive=true`, and `Fields=UserData`. Do not assume punctuation from a spoken title—e.g. a requested `All Creatures Great and Small` may be catalogued as `All Creatures Great & Small`.
2. Enumerate all nested `Episode` items for that series with `ParentId=<series API ID>` and `Fields=UserData`; record watched, play count, and resume positions. Inspect both source and destination first; refuse an overwrite if the destination has existing progress unless the user expressly requests merging/overwriting.
3. For an exact transfer including play counts and resume ticks, stop Jellyfin cleanly, use SQLite's backup API to make a temporary rollback copy, and transact against `UserData` only. Scope items by normalized `BaseItems.Id`/`SeriesId`.
   - Copy only progress fields (`LastPlayedDate`, `PlayCount`, `PlaybackPositionTicks`, `Played`) to the target; preserve target favourites, ratings, likes, and stream preferences when a target row already exists.
   - Clear the source progress by setting `LastPlayedDate=NULL`, `PlayCount=0`, `PlaybackPositionTicks=0`, and `Played=0`. Do not delete the row wholesale, as it can hold non-progress preferences.
   - Preserve `CustomDataKey` in the `UserData` composite key.
4. Verify transactionally that target progress rows equal the source's former rows and source has no non-zero played/count/position or last-played values within the exact show scope.
5. Restart Jellyfin, wait for its API listener rather than relying only on a stale Docker health status, and re-query both users' episode data through the API. Confirm watched count and special/episode resume ticks moved, and source totals are zero. Remove the temporary rollback database only after those checks pass.

## Pitfalls

- `POST /Users/New` expects JSON, not an empty request with `Name`/`Password` query parameters.
- API display IDs omit UUID hyphens; database IDs retain them.
- `Mark unplayed` semantics can leave historical play counts in some data states, so an explicit scoped reset is needed when the request is to **clear progress**, not merely uncheck watched.
- Docker may report a health state from a prior check while Jellyfin's Kestrel listener is still starting. Retry the local API probe after startup logs show it is listening.
