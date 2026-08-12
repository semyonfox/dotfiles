# Slidev handover plus temporary public sharing

Use when a Slidev presentation has been iterated heavily and Semyon asks to update/make a handover and expose the slides publicly for a short interview/demo window.

## Handover shape

A good handover for this class of deck should include:

- current goal/audience and the intended story arc
- current local project path and live URLs
- systemd/static service name if hosted
- public tunnel hostname/service if exposed
- current visible slide flow, copied from `slides.md` headings
- files changed, including generated assets and scripts
- architecture facts to preserve, split into historical/current/future where needed
- speaker-note conventions and style constraints
- build and verification commands
- exact latest verification results
- known harmless warnings
- how to stop/remove temporary public exposure
- what to prioritize if doing one more quick pass

Do not leave the handover describing an obsolete 7-slide or previous-flow version after rewriting to 15 slides. If the slide flow changed, update the handover's slide list from the actual headings.

## Public sharing checklist

1. Build/check the deck first.
2. Prefer serving built `dist` through the existing static service rather than exposing a dev server.
3. If using Cloudflare Tunnel, create a named temporary tunnel and a user systemd service rather than a foreground process.
4. Verify:

```bash
systemctl --user is-active <static-deck>.service
systemctl --user is-active <tunnel>.service
curl -I --max-time 10 http://127.0.0.1:<port>/
curl -I --max-time 20 https://<host>/
curl -I --max-time 20 https://<host>/<important-diagram-or-asset>
```

5. Open the public URL in a browser/visual check to confirm it renders the actual title slide and not an error/interstitial.
6. Put the stop command in the final response and handover:

```bash
systemctl --user disable --now <tunnel>.service
```

## Why this matters

Interview decks are often edited under time pressure. A public URL that returns 200 but has missing SVGs, stale flow notes, or undocumented tunnel cleanup is a future foot-gun. Treat handover + public exposure as part of delivery, not admin afterthought.
