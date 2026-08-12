# Network-infrastructure management game — concept seed

## Product intent

A mobile-first game deliberately opposed to live-service sludge: quick startup, modest device requirements, predominantly offline play, no forced account, no energy timers, no pay-to-win, no loot boxes, and no mandatory ads. Suitable later monetisation: one-time unlock, expansions, cosmetics, supporter packs, or genuinely optional rewarded ads.

## Pitch

**Mini Metro/Mini Motorways-style pressure management where the traffic is internet traffic and the crises are infrastructure incidents.** The player starts with two university computers and expands through campus and regional networks toward large infrastructure.

It must feel like reading pressure and choosing trade-offs, not like configuring Cisco equipment.

## Strong first playable

An 8–10 minute university-computer-lab scenario:

1. Normal browsing and voice traffic establishes the visual language.
2. Large student downloads saturate a link.
3. A lecturer stream raises the priority stakes.
4. Player upgrades capacity or protects real-time traffic.
5. Main cable degrades/fails; player reroutes.
6. Optional 10–20 second cable reconnect/untangle interaction provides hands-on repair.
7. Recovery and score/restart close the loop.

Prototype verbs: place/replace link; upgrade capacity; set Critical/Real-time/Bulk priority; reroute around fault; brief repair action.

## Simple simulation shape

- Nodes: PC, switch, server, Internet; each has type and health.
- Links: endpoints, capacity, latency, health, enabled state.
- Traffic demands: source, destination, class, requested bandwidth, priority weight.
- Each tick: generate demand; route over enabled links; allocate higher priorities first; calculate utilisation; derive congestion/latency/loss; calculate service score; render representative packet particles.
- Readability thresholds: under ~70% green, 70–90% amber, over 90% red, over capacity visibly drops/degrades lower-priority traffic.

Do not simulate individual packets, full routing protocols, or technically exact QoS in the first prototype.

## Explicit v1 exclusions

No staff/contractors, wireless tuning, cooling systems, physical town-cable placement, national infrastructure, multi-currency economy, research tree, daily challenges, random incidents, ads/IAP, cloud saves, Steam, or public multiplayer.

Use scripted incidents first so the pressure curve can be tested and tuned.

## Related later idea

A blocky, fast, compact-map shooter inspired by the older *feel* of Pixel Gun 3D—not its protected content—could follow later. Build it offline first, then bots, private/local multiplayer, and only much later public matchmaking. It is not the sensible first project because public shooters require authoritative servers, matchmaking, lag compensation, anti-cheat, moderation, balancing, and active population.
