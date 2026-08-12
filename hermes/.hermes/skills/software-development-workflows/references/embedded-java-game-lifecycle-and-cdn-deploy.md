# Embedded Java game lifecycle and CDN deployment

## Symptom cluster

An embedded Swing game can load its CheerpJ/browser shell normally yet freeze immediately after a start key. Browser console may show an exception from the Java game thread, often as `Unknown Source` when the JAR lacks line metadata. A simultaneous jump from wave 1 to wave 2 with no score is a strong sign of startup state being observed halfway through initialization.

## Root cause pattern

A loop thread reads `isGameInProgress` while the event thread is still creating player/enemy objects. If the flag is set first:

- collision code can dereference a null player;
- an initially all-null enemy array can appear defeated and advance the wave;
- a thrown exception terminates the loop, leaving the last frame frozen.

## Safe lifecycle pattern

1. Set gameplay inactive before rebuilding the world.
2. Reset all run state: score, money, wave/frame counters, health/cooldowns, bullets, input flags, boss state, and effects from upgrades.
3. Create player, enemies, upgrade UI, and projectile collection.
4. Set `isGameInProgress = true` last. Make it `volatile` or synchronize publication.
5. Keep defensive null guards at collision calls.
6. Use a distinct `isGameOver` flag rather than inferring game-over from a positive score, so a score-zero loss renders correctly.

## Enemy bounds

Horizontal edge reversal is not a vertical loss rule. On each active frame, check whether any alive enemy’s bottom crosses a defined player/invasion line. End the game before it can march below the player or off screen. Retain direct sprite collision as a separate loss/damage route.

## Economy review checklist

- Price basic early upgrades from the actual first-wave payout.
- Avoid an unintended first-level multiplier such as charging `base * 1.6` at level zero unless that is deliberate.
- Make major upgrades expensive but reachable during ordinary progression.
- Give max-health upgrades immediate current-health value if they are bought in combat.
- Decide clearly whether upgrades are per-run or meta-progression. If per-run, reset both UI level state and the underlying stat effects.

## Build and deployment verification

1. Compile all Java classes and create a fresh JAR; list its classes and hash it.
2. Replace the portfolio/static-site JAR artifact in a clean worktree.
3. Run the site’s native check and production build.
4. Commit/push source and artifact separately when they live in separate repositories.
5. Confirm the CI/Jenkins checkout SHA, completed deploy status, and the serving container’s artifact hash.
6. Probe the public URL too, but compare origin/container and CDN results separately. A long asset TTL can leave a correct deployment serving an old edge-cached JAR. Purge the precise URL through the CDN only when authorized and authenticated.
