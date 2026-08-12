# Mobile stale-cursor snapshot guard

Use when a T3 Code mobile/remote client is slow or appears frozen after activity on another device, while the backend remains healthy.

## Symptom and diagnosis

A warm client cache stores an `OrchestrationShellSnapshot` and reconnects with `afterSequence`. Current `subscribeShell` behavior may attach a live buffer and then call:

```ts
orchestrationEngine.readEvents(afterSequence, Number.MAX_SAFE_INTEGER)
```

It maps/filter events into shell changes **after** reading them. An old cursor against a large append-only `orchestration_events` store can therefore scan/replay millions of irrelevant streaming events before the client becomes current.

Do not diagnose this as a tunnel or generic server failure until checking:

- `t3-code-headless.service` and origin/public health;
- event-store size and event-type counts;
- active-thread count versus historical/deleted threads;
- most recent active-thread timestamps.

## Intended architecture

T3 Code is not supposed to rebuild the server database on the phone.

- **Cold cache:** client fetches a fresh shell snapshot (HTTP, gzip-friendly), then subscribes from that snapshot sequence.
- **Warm recent cache:** client sends `afterSequence`; server replays only the small delta, then live events.
- **Shell snapshot contents:** project/thread shell metadata, active thread summaries, sessions, latest turns, and a sequence boundary. It does not include thread-message history; thread details are separately lazy-loaded.

The normal active-thread snapshot filters `deleted_at IS NULL` and `archived_at IS NULL`; sessions/latest turns are similarly joined to active threads. Verify project filtering separately: some versions preserve soft-deleted project metadata with `deletedAt` rather than SQL-filtering it.

The existing live subscription is intentionally attached before catch-up, into a scope-bound buffer, so events published during catch-up are not lost. Clients dedupe overlaps by sequence.

## Correct server-side fix

Add a stale-cursor guard in the server's `subscribeShell` path:

1. Attach the scoped live buffer first.
2. Determine whether `afterSequence` is close enough to a current authoritative boundary.
3. If the cursor is stale (initially a server-side constant around 5,000–10,000 events) or ahead of the server, send `getShellSnapshot()` and then drain buffered/live items.
4. Otherwise retain existing small-delta replay and then drain buffered/live items.

Conceptually:

```ts
if (gap > MAX_SHELL_REPLAY_EVENT_GAP || cursorAheadOfServer) {
  return Stream.concat(
    Stream.succeed({ kind: "snapshot", snapshot: yield* getShellSnapshot() }),
    Stream.fromQueue(liveBuffer),
  );
}
return Stream.concat(catchUpReplay, Stream.fromQueue(liveBuffer));
```

Use the **actual fresh snapshot's sequence** as the authoritative boundary. Snapshot items are already protocol-compatible with clients that consume shell streams.

### Important nuance

`getSnapshotSequence()` may represent projection progress rather than the exact event-store tail. It is a sensible immediate stale-cursor guard when projections normally keep up, but a fully strict replay-cost bound would eventually use an inexpensive event-tail/high-water query (or a bounded "more than N events after cursor" query). Do not let this nuance block the immediate fix.

## Alternatives and tradeoffs

- **Always snapshot:** safe but regresses normal reconnect efficiency for environments with many projects/threads.
- **Client cache expiry only:** helpful secondary hygiene, but insufficient; any TTL can become stale during a high-volume run and older clients still need server protection.
- **Bounded replay without snapshot fallback:** incorrect, because shell-relevant changes after unrelated global events could be skipped.

## Regression tests

- Recent cursor: replay is used, no snapshot fallback.
- Stale cursor: emits one snapshot and never calls `readEvents`.
- Cursor ahead of server: authoritative snapshot reset, no replay.
- Race: event arriving after buffer attachment but while snapshot loads is represented by snapshot or delivered after it; never lost.
- Overlap: buffered event at/before snapshot sequence is ignored client-side; later event applies.
- Deleted/archived stale entries vanish from normal-shell state after fallback.
- Boundary values: exact threshold, threshold + 1, zero, and ahead cursor.
- Preserve typed errors and scoped cleanup for snapshot/replay failure.

## Upstream contribution framing

`CONTRIBUTING.md` says the project is not actively accepting contributions, but explicitly identifies small focused bug, reliability, and performance fixes as most likely to be accepted. For this change:

1. Open an issue first because the protocol/reconnect behavior is non-trivial.
2. Give an observed reproduction with event-store scale, not private data.
3. Keep the PR server-only, minimal, and tested; do not mix DB pruning, UI work, or project-filter cleanup.
4. Explain that it preserves normal delta sync while protecting stale/mobile clients from unbounded replay.
