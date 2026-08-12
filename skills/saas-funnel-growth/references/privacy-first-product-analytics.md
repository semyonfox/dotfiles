# Privacy-first product analytics across multiple apps

## Recommended architecture

Keep collection native to each application and standardize only the aggregate vocabulary:

- Public acquisition: cookieless page/CTA events, no browser identifier or storage.
- Product activation: authenticated or server-canonical milestones.
- Operational telemetry: Sentry or equivalent for errors, kept separate from behavioural analytics.
- Central reporting: Grafana or Metabase reads aggregate daily metrics from each app.
- Never create a shared cross-app person identifier or centralize raw user-event rows by default.

Useful common dimensions are `project`, `environment`, `day`, `event_name`, and `count`. Keep app-specific event details inside the app.

## Provider choices

- Plausible is a sensible public-acquisition layer when configured cookielessly.
- Sentry is useful for operational errors, not funnel analysis; keep replay/profiling disabled unless separately justified.
- PostHog can be useful when its product-analysis features add distinct value, but remove or disable it when it merely mirrors first-party events. Memory-only persistence still adds dependency and governance complexity.
- Avoid GA4/GTM, advertising pixels, heatmaps, and session replay when the requirement is useful analytics without consent-banner sludge.

## Implementation review checklist

1. Check live production and development sites, not only repository code.
2. Inspect cookies, localStorage, sessionStorage, loaded scripts, and analytics network requests.
3. Remove anonymous session IDs and attribution storage if a no-storage design is required. Event-level UTM attribution is the clean fallback.
4. Strip URL query strings/fragments, arbitrary button text, user-agent strings, and client-provided timestamps.
5. Honor DNT and Global Privacy Control on both client and server.
6. Make important activation events server-canonical to prevent duplicates and client spoofing.
7. Keep explicitly submitted public milestones, such as an access request, only as aggregate server events with no actor key.
8. Use a dedicated HMAC secret for pseudonymous authenticated analytics. Never reuse JWT secrets.
9. Add bounded retention and aggregate-only admin/reporting surfaces.
10. Document required runtime variables in checked-in environment templates.

## Verification and PR workflow

- Work in one clean worktree and agent-owned branch per repository.
- Run focused analytics/privacy tests plus the project-native typecheck/build.
- Treat pre-push hooks as additional verification, not the only source of truth. If an external shared-service collision blocks a hook after equivalent checks passed, report it explicitly and push with hook bypass only when justified.
- Inspect CodeQL annotations, not merely the red status. Test fixtures using hard-coded cryptographic salts can trigger real checks; replace them with runtime-generated values and rerun CI.
- Open separate draft PRs per repository and wait for checks before reporting completion.

## Reporting to Semyon

Keep the final report compact: architecture verdict, what was kept/removed, PR links, verification, and genuine blockers. Do not narrate every file or agent step unless asked.