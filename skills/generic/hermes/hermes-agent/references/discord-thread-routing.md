# Discord thread routing notes for Hermes Gateway

Research context: public Hermes docs, Hermes Discord adapter source, public GitHub issues/blogs, and visible community/search results around Discord setup and threads.

## Authoritative Hermes behavior

- Discord gateway is not stateless webhook forwarding. Messages pass through authorization, mention/free-response checks, session lookup, transcript loading, normal Hermes agent execution, and delivery.
- DMs respond to every message and get their own sessions.
- Server channels normally require `@mention` unless configured as free-response or global `require_mention: false`.
- Free-response channels respond inline and skip auto-threading. This is a convenience surface, not a thread-isolated task surface.
- Threads reply in the same thread and are isolated from parent channel history.
- By default, shared channels isolate session history per user (`group_sessions_per_user: true`).
- Parent channel IDs are considered for several Discord controls, so threads can inherit parent allow/free/ignore prompt behavior depending on the code path/version.
- `thread_require_mention: false` means a bot that has participated in a thread keeps responding without repeat mentions. Good for one-bot task threads.
- `thread_require_mention: true` gates threads like channels. Good for multi-bot/shared-thread setups.

## Configuration pattern that emerged

For a server with role/persona channels:

1. Use channels as inboxes/launchpads.
2. Use Discord threads as the actual task contexts.
3. Keep only a lobby/control channel as free-response, if any.
4. Make specialist channels mention-gated so `auto_thread: true` can create a fresh thread per task.
5. Keep `group_sessions_per_user: true` unless the user explicitly wants a shared room brain.

Example:

```yaml
discord:
  require_mention: true
  free_response_channels:
    - "<lobby_channel_id>"
  allowed_channels:
    - "<lobby_channel_id>"
    - "<specialist_channel_id>"
  auto_thread: true
  thread_require_mention: false
  history_backfill: true
  history_backfill_limit: 50
  reactions: true

group_sessions_per_user: true
```

If all channels should stay tidy, use no free-response channels and start everything with a mention.

## Permission checklist for Discord threads

Check the bot role has:

- View Channel
- Read Message History
- Send Messages
- Create Public Threads
- Create Private Threads, if private threads are used
- Send Messages in Threads
- Add Reactions, if `reactions: true`
- Manage Threads only for locked/admin thread workflows, not as a default requirement

## Public/community signals

- Public blog/setup guides consistently recommend: start in one private channel, use narrow scopes/permissions, configure allowlists, restart gateway, then verify with a real Discord message.
- A visible Discord support-agent repo used the same architecture: user posts in a channel, bot creates a thread, follow-ups continue there with isolated history and optional human escalation.
- An open Hermes feature request proposed category-level rules such as `free_response_categories`, `ignored_categories`, and `require_mention_categories`; until supported by the installed version, enumerate channel IDs.
- A historical Hermes issue reported Discord thread session context not restoring; current docs/source indicate thread session behavior exists, but when troubleshooting always verify on the installed version and restart stale gateways after updates.

## Common diagnosis matrix

- Bot online but silent: Message Content Intent, allowlist/role authorization, require-mention policy, active profile/env mismatch, channel permissions, or stale gateway process.
- No thread created: channel is free-response/no-thread, `auto_thread` false, message is already in a thread/DM, bot lacks thread permissions, or message was treated as a reply path that bypasses auto-threading.
- Context feels messy: free-response inline chat used for deep work, `group_sessions_per_user: false`, or too many unrelated tasks in one thread/channel.
- Multiple bots spam a thread: set `thread_require_mention: true` or separate bots by channel/category/profile.
