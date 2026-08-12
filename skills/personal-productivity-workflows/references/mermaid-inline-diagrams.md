# Mermaid inline diagrams for Semyon's portfolio posts

Use when adding Mermaid-rendered architecture/workflow diagrams to Astro Markdown posts.

## Preferred shape

- Render Mermaid to a real image (`.webp` preferred, `.png` fallback); do not embed raw Mermaid unless the site explicitly supports it.
- For narrow blog columns, use one compact diagram that preserves the relevant structure without becoming a giant map.
- If the user says they preferred an earlier diagram structure, keep the structure/grouping and improve presentation; do not replace it with a generic simplified strip.
- For Hermes/agent posts, diagrams should show the actual concepts being discussed: gateway, profiles, channel prompts/workflows, cron jobs, subagent/agent loops, server tools, repos/files, memory, and skills.

## Mermaid styling notes

- Mermaid `subgraph` blocks can render with pale default backgrounds that look awful on the dark portfolio theme.
- If using subgraphs, try explicit transparent cluster styling:
  - `themeVariables.clusterBkg: "transparent"`
  - `themeVariables.clusterBorder: "#334155"`
  - `themeCSS` targeting `.cluster rect { fill: transparent !important; }`
- If pale blocks remain in the screenshot, avoid subgraphs and use labelled/dashed nodes as grouping labels instead.
- Avoid tiny edge labels. They become unreadable in the rendered article column.

## Render pattern

Known-good pattern from this session:

```bash
cat >/tmp/puppeteer-no-sandbox.json <<'JSON'
{"args":["--no-sandbox","--disable-setuid-sandbox"]}
JSON

PUPPETEER_EXECUTABLE_PATH=/path/to/chrome-headless-shell \
  pnpm dlx @mermaid-js/mermaid-cli@latest \
  -p /tmp/puppeteer-no-sandbox.json \
  -i src/content/blog/<diagram>.mmd \
  -o public/blog/<diagram>.png \
  -b transparent \
  -w 1150 -H 600 -s 1

convert public/blog/<diagram>.png \
  -define webp:lossless=true -quality 90 \
  public/blog/<diagram>.webp
rm -f public/blog/<diagram>.png
```

Do not save temporary Puppeteer config files inside the repo unless they are intentionally part of the project.

## QA checklist

- Run `pnpm run build`.
- Count words if the user gave a target.
- Check disallowed private/persona names with a literal/word-boundary search.
- Validate the image:
  - format is WebP/PNG/JPEG/GIF, not Mermaid/SVG text accidentally passed around
  - corners have alpha `0` for transparent diagrams
  - file size is reasonable
- Open the rendered page and take a screenshot around the actual diagram location.
- Reject and re-render if:
  - it has a pale/white Mermaid cluster background
  - it is too tall and dominates the article
  - text is unreadably tiny
  - it no longer represents the structure the surrounding text explains
