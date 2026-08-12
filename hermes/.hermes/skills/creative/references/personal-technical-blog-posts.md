# Personal technical blog posts

Use this reference when helping Semyon draft or publish personal technical blog posts, especially posts about his own tooling, homelab, AI setup, or portfolio.

## Durable workflow

1. Inspect the target site structure before drafting: content directory, frontmatter schema, existing posts, route naming, and build command.
2. Read nearby posts to match voice. Semyon's portfolio blog style is direct, personal, practical, and lightly opinionated; avoid corporate/marketing phrasing.
3. If the post discusses live personal infrastructure, read relevant local config/status where permitted, but redact/avoid exact IDs, tokens, phone numbers, hashes, allowlists, or private routing details in public prose.
4. Turn raw config into a mental model for readers: what the system is, why it matters, how it is structured, and what ladder a beginner could follow.
5. Write the article as a real file in the content system, not as a detached draft in chat, unless the user explicitly asks for copy only.
6. Verify with the project's real build/check command and report actual output.
7. Check git status/diff and clearly separate newly-created files from pre-existing user changes.

## Voice notes

- Prefer first-person concrete experience over generic tutorial voice.
- Use short paragraphs and blunt transitions.
- Keep technical terms, but explain the mental model rather than dumping config.
- Strong angle beats broad coverage: e.g. “Hermes is my AI layer over the machine” is better than “Overview of Hermes features”.

## Privacy notes

Safe to mention architecture and categories: Discord/WhatsApp gateway, personalities, profiles, memory, skills, provider-agnostic models, systemd gateway, local terminal access.

Avoid publishing: channel IDs, WhatsApp group IDs, phone numbers, dashboard password hashes/secrets, exact allowlists, API keys, auth file contents, and anything that would make the public post a map of private infrastructure.
