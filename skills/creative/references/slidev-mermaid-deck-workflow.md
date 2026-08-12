# Slidev + Mermaid Technical Deck Workflow

Use this when building or repairing technical architecture decks that embed Mermaid diagrams as rendered SVG/PNG assets.

## Style lessons

- Do not over-sanitize the deck into generic AI-looking minimalism. If the user prefers an accent color, keep it. In this session, Semyon preferred the warm orange/amber accent after seeing a colder blue/grey version.
- Preserve practical visual character while fixing actual legibility issues.
- Code/accent colors can be expressive as long as the content remains readable.

## Diagram clipping fix

Mermaid SVGs can render with a viewBox that sits exactly on the outer stroke/text bounds. When Slidev puts the SVG inside an `overflow: hidden` zoom/pan frame, bottom/right borders may look clipped even though the source is technically valid.

Reliable fix:

1. Render Mermaid diagrams to SVG/PNG as usual.
2. Post-process SVG files by padding the root `viewBox`.
3. Do not inject comments into the opening `<svg ...>` tag; put any marker after the opening tag or omit it.
4. Re-copy padded SVGs into `public/` and re-run the static build if needed.
5. Verify in the actual browser frame, not just by checking SVG file dimensions.

Minimal post-process pattern:

```python
import re
from pathlib import Path

PADDING = 96
VIEWBOX_RE = re.compile(r'viewBox="([\-\d.]+)\s+([\-\d.]+)\s+([\d.]+)\s+([\d.]+)"')

for path in Path('dist/diagrams/rendered').glob('*.svg'):
    text = path.read_text(errors='ignore')
    if 'oghma-viewbox-padded' in text:
        continue
    match = VIEWBOX_RE.search(text)
    if not match:
        continue
    x, y, width, height = map(float, match.groups())
    replacement = f'viewBox="{x - PADDING:g} {y - PADDING:g} {width + PADDING * 2:g} {height + PADDING * 2:g}"'
    text = VIEWBOX_RE.sub(replacement, text, count=1)
    text = text.replace('>', '>\n<!-- oghma-viewbox-padded -->', 1)
    path.write_text(text)
```

## Slidev SVG autofit component pattern

For zoomable SVG diagrams, do not rely on browser `naturalWidth`/`naturalHeight` for SVGs; these may be default intrinsic dimensions like `300x150` instead of the real viewBox. Fetch the SVG text, parse the root `viewBox`, set explicit CSS `width`/`height`, then compute fit-to-frame scale.

Important component behavior:

- Fetch `src` with `cache: 'no-store'` or add a query cache buster when regenerating diagrams.
- Use the parsed viewBox width/height for layout and fit math.
- Fit by default with margin: `scale = min((frameWidth-margin)/svgWidth, (frameHeight-margin)/svgHeight)`.
- Center after fitting.
- Keep `fit` and `100%` controls available.
- Use `overflow: hidden` only for the zoom frame; code blocks should use `overflow: auto` so content is not silently clipped.

## Remote hosting/debugging pattern

If a deck is hosted on a server and the chosen LAN port times out from the user's PC:

1. Test from the user's PC, not just from the agent host.
2. Check whether common ports like `22`, `80`, `443` work while the custom deck port fails.
3. If sudo/firewall changes are unavailable, leave the deck hosted on the server and create a local SSH forward on the PC, for example:

```ini
[Service]
ExecStart=/usr/bin/ssh -N -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -L 127.0.0.1:3037:127.0.0.1:3037 server
Restart=always
RestartSec=2
```

Then have the user open `http://127.0.0.1:3037/`; the content is still served from the server via the tunnel.

## Verification checklist

- Render all Mermaid assets successfully.
- Build Slidev successfully.
- Inspect the actual browser view for bottom/right clipping.
- Verify key diagram URLs return HTTP 200.
- If deployed remotely, verify from the user's machine or equivalent path, not only from localhost on the server.
