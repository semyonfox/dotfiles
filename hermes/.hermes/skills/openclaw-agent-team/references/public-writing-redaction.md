# Public writing about the OpenClaw/Hermes agent team

Use this when Semyon is writing a blog/guide/talk/post about his Hermes/OpenClaw-style agent setup.

## Default posture

Prefer **role names over persona names** in public drafts unless Semyon explicitly chooses to publish the names.

Good public labels:
- chief of staff / planner
- developer / code reviewer
- infrastructure engineer
- monitoring sentinel / watchdog
- support / social sanity checker
- root/default coordinator

Avoid by default:
- friend-inspired names
- names tied to real people or private admiration/context
- WhatsApp community/group names
- Discord channel names/IDs
- private screenshots/transcripts
- exact routing IDs, phone numbers, webhooks, invite URLs, tokens, API keys, `.env` snippets, auth files, provider credentials

## Reasoning

The useful public lesson is the architecture, not the private lore. Once a persona name maps to a real friend, inside joke, admiration target, or emotional support role, publishing it can leak personal context and distract from the technical guide.

Semyon's agents have seen private operational material: env vars, passwords/tokens, config dumps, server logs, personal chats, and urgent debugging context. Public writing should describe the **pattern** without exposing the **private routing layer**.

## Safe framing

When drafting public content, say things like:

- "I have a planning agent, a code agent, an infrastructure agent, and a monitoring agent."
- "Some have private names, but the public point is the role architecture."
- "One gateway handles Discord/WhatsApp, then channel prompts or profiles provide specialist behaviour."

## Architecture phrasing

A safe diagram/description:

```text
Discord / WhatsApp / CLI
          ↓
      Hermes Gateway
          ↓
   default/root profile
          ↓
channel prompt, subagent, cron job, or specialist profile
```

Recommended public lesson:

- Use one gateway for platform IO.
- Use channel prompts for lightweight specialist routing.
- Use profiles for real identity/memory isolation.
- Use skills for reusable procedures.
- Use memory for durable facts.
- Use cron for scheduled automation.

## Review checklist before publishing

- [ ] No `.env` contents, API keys, bot tokens, OAuth artifacts, or auth file snippets.
- [ ] No Discord/WhatsApp channel IDs, group IDs, phone numbers, webhook URLs, invite links, or account IDs.
- [ ] No private chat excerpts unless deliberately sanitized and approved.
- [ ] Agent/persona names replaced with roles unless Semyon explicitly wants names public.
- [ ] Screenshots cropped/redacted for names, IDs, paths, domains, IPs, and private conversations.
- [ ] Setup prompt tells the agent to pause for human-only steps like Discord Developer Portal setup, OAuth approval, or WhatsApp pairing.
