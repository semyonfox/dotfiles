# Remote artifact galleries and formal diagram handoff

Use when Semyon asks to move rendered project artifacts (PNG/SVG/PDF) to a device and open them there, or asks to refine the local webpage/gallery you created for those artifacts.

## Key pitfall: gallery vs app repo

If Semyon says “the webpage” after you created/opened a local gallery on a laptop/PC, assume he means that generated gallery file first — not the production app homepage. Do not edit the app repository until you have evidence he means the app itself.

Good check:

```bash
ssh <device> 'find ~/Downloads ~/Pictures -maxdepth 2 -name "*gallery*.html" -o -name "OghmaNotes-*" | sort | tail -20'
```

## Filtered local galleries

For lots of images, create a static HTML gallery on the destination device instead of opening dozens of files individually. Keep the original files unbundled; the gallery only references them.

Typical pattern:

```bash
DEST="$HOME/Downloads/OghmaNotes-png-YYYYMMDD-HHMMSS"
GALLERY="$DEST/gallery.html"
python3 - "$DEST" "$GALLERY" <<'PY'
from pathlib import Path
import html, sys
root = Path(sys.argv[1]); out = Path(sys.argv[2])
# Choose intent-specific patterns. For architecture-only, avoid UI screenshots.
patterns = [
    "diagrams/rendered/*.png",
    "screenshots/demo-architecture*.png",
    "screenshots/diagram-*.png",
]
imgs = []
for pat in patterns:
    imgs.extend(root.glob(pat))
imgs = sorted(dict.fromkeys(imgs), key=lambda p: p.as_posix())
body = "\n".join(
    f"<figure><img src='{html.escape(p.relative_to(root).as_posix())}'><figcaption>{html.escape(p.relative_to(root).as_posix())}</figcaption></figure>"
    for p in imgs
)
out.write_text(f"""<!doctype html><meta charset='utf-8'><title>Artifact gallery</title>
<style>body{{font:14px system-ui;background:#111;color:#eee;margin:24px}}figure{{margin:0 0 32px;padding:16px;background:#1b1b1b;border-radius:12px}}img{{max-width:100%;height:auto;background:white;border-radius:8px}}figcaption{{margin-top:8px;color:#bbb}}</style>
<h1>Filtered artifact gallery ({len(imgs)})</h1>{body}""")
PY
```

Open in the active Wayland session using the browser Semyon asked for. On his Cachy/Hyprland devices, the Helium binary may be `/opt/helium-browser-bin/helium`, not on the systemd user PATH:

```bash
ssh semyon@100.127.128.15 '
  export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus DISPLAY=:0
  systemd-run --user --collect \
    --setenv=XDG_RUNTIME_DIR=/run/user/1000 \
    --setenv=WAYLAND_DISPLAY=wayland-1 \
    --setenv=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
    --setenv=DISPLAY=:0 \
    /opt/helium-browser-bin/helium "file://$HOME/Downloads/.../gallery.html"
'
```

## Formal Mermaid-rendered diagram galleries

When Semyon asks for “actual Mermaid rendered ones,” generate `.mmd` source plus rendered `.svg` and `.png`, then build an HTML index with descriptions and links to all three formats.

For Semyon’s demo/interview pages, keep the gallery extremely plain: barely styled HTML, simple dark grey background (`#222` is fine), system font, normal links, short descriptions, and inline rendered diagrams. Avoid dashboard polish: cards, gradients, shadows, sticky/glassy nav, marketing copy, and anything that reads as “AI-generated landing page.”

Minimal gallery style that matches his preference:

```html
<style>
  body { margin: 24px; max-width: 1200px; background: #222; color: #eee; font: 16px/1.45 system-ui, sans-serif; }
  a { color: #8ab4ff; }
  nav { margin: 16px 0 28px; }
  section { margin: 0 0 40px; }
  h1, h2 { margin-bottom: 6px; }
  p { margin-top: 0; color: #ccc; }
  img { max-width: 100%; height: auto; background: white; }
</style>
```

Renderer pattern that worked:

```bash
npm exec --yes --package @mermaid-js/mermaid-cli --package puppeteer -- mmdc --version
npm exec --yes --package @mermaid-js/mermaid-cli --package puppeteer -- \
  mmdc -i diagram.mmd -o diagram.svg -c mermaid-config.json -p puppeteer-config.json -b white
npm exec --yes --package @mermaid-js/mermaid-cli --package puppeteer -- \
  mmdc -i diagram.mmd -o diagram.png -c mermaid-config.json -p puppeteer-config.json -b white -s 2
```

`puppeteer-config.json` for headless Linux:

```json
{"args":["--no-sandbox","--disable-setuid-sandbox"]}
```

Use a Mermaid theme config with a white background and readable dark text for formal diagrams. Verify every gallery reference exists before claiming success:

```bash
python3 - <<'PY'
from pathlib import Path
import re
p = Path('formal-mermaid-gallery.html')
text = p.read_text()
refs = re.findall(r'(formal-mermaid/[^"\']+\.(?:svg|png|mmd))', text)
missing = [r for r in refs if not (p.parent / r).exists()]
print('images', text.count('<img '), 'links', len(refs), 'missing', missing)
raise SystemExit(bool(missing))
PY
```

## Reporting

Report the exact destination path, count of diagrams/images, whether the gallery was reopened, and any correctness caveat (for example: “old schema screenshot is stale; generated ERD reflects migrations and Qdrant split”).