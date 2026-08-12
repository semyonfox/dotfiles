---
name: social-platform-operations
description: "Operate social and messaging platforms from Hermes: X/Twitter via xurl and Yuanbao group/DM workflows."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos]

metadata:
  harness: [hermes]
---

# Social Platform Operations

Use this umbrella when the user asks to read, post, search, DM, mention users, or inspect groups on social/messaging platforms that Hermes can access through platform-specific tools or CLIs.

## Safety and identity rules

- Confirm the target account/channel/group when ambiguity could cause a public post or wrong-recipient message.
- Never expose API keys, OAuth tokens, cookies, or authorization headers.
- For posting, quote the exact outgoing text before sending if user intent is ambiguous or high-impact.
- For searches and reads, preserve URLs/IDs/timestamps when reporting results.

## LinkedIn / signed-in browser context

Hermes's normal browser session may not be signed into LinkedIn. When Semyon says LinkedIn is signed in on his PC/Helium, use the PC browser fallback instead of assuming the hosted browser can access it:

```bash
ssh pc 'export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/1000/hypr | head -1); hyprctl dispatch exec "helium-browser https://www.linkedin.com/messaging/"'
ssh pc 'export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/1000/hypr | head -1); grim /tmp/hermes-linkedin.png'
scp pc:/tmp/hermes-linkedin.png /tmp/hermes-linkedin.png
```

Use this for read-only context gathering or opening pages for Semyon to interact with. Do not blindly click, send LinkedIn messages, accept connections, or modify account/security settings through the PC browser without explicit permission. If screenshot/text extraction is enough, prefer that over taking over the session.

## Discord / gateway file attachments

When the user explicitly asks to send/attach a file in Discord, prefer `send_message` with a `MEDIA:/absolute/path` attachment in the message body rather than relying on a final assistant response to render as an attachment. In gateway contexts, a bare final `MEDIA:` line can be delivered as text depending on adapter/rendering path; `send_message` returns a platform message ID and verifies the side effect.

Checklist:
- Make sure the target is the current Discord channel/thread when the request says "send it here"; if the target is ambiguous, list targets first.
- Use an actual file path and an attachment-friendly extension (`.txt`, `.md`, `.zone`, etc.). If needed, duplicate content to `.txt` for Discord/client compatibility.
- Report the Discord message ID after sending.

## X / Twitter via `xurl`

Use `xurl` for X API operations: posts, reads, searches, DMs, media upload, and v2 endpoints. Check installation/auth before relying on it. Prior detailed recipe: `references/xurl.md`.

### Drafting short public replies and follow-up DMs

When the user asks for help applying to a beta, replying to a founder, or otherwise drafting a concise X post:

- Lead with concrete, relevant evidence of real use rather than generic enthusiasm. A real test environment, prior hands-on use, bug reproduction ability, or an unusual failure mode is valuable evidence.
- Frame unreliable connectivity or imperfect infrastructure as meaningful failure-case coverage, not as an apology.
- Do not name an unreleased/private project, employer, client, or other confidential work in a public post unless the user explicitly approves naming it.
- If a hard character limit applies, calculate the final text's character count before stating it fits. Prefer a safety margin rather than writing to the exact limit.
- If the user says “just the message,” return only the copy-pasteable message: no intro, headings, count, rationale, or alternatives.
- Keep a requested email DM minimal. A bare address is sufficient; one short context line is the maximum useful padding. Do not add a biography or repeat the public pitch.
- Drafting is not authorization to publish. Only post/DM via a platform tool after the user explicitly requests the side effect.

## Yuanbao groups and DMs

Use the Yuanbao toolset for group member lookup, @mentions, direct messages, and group information queries. Respect the tool's distinction between group and direct-message targets. Prior detailed recipe: `references/yuanbao.md`.

## Discord / gateway file delivery

When the user explicitly asks for a file attachment in Discord, send it through the messaging tool with `MEDIA:/absolute/path` in the message body and the exact Discord target when known. A final assistant response containing `MEDIA:` may render as plain text depending on the gateway surface; verify with a returned message ID from `send_message` when the user needs the actual attachment.

## Verification checklist

- [ ] Correct platform and target were identified
- [ ] Auth/readiness was checked before platform calls
- [ ] User-visible side effects were intentional
- [ ] Files the user asked to receive as attachments were sent with `send_message` + `MEDIA:/absolute/path`, not only pasted in chat
- [ ] Final response includes stable handles such as message IDs, URLs, or group names when available
