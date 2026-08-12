# WhatsApp Community Routing for OpenClaw-Style Agents

Session-derived troubleshooting note for migrating the old OpenClaw agent-team pattern into Hermes over WhatsApp Communities.

## Symptom

Semyon has a WhatsApp Community with one group per persona/agent plus a General group. Messages sent from Semyon's own WhatsApp account into those groups appear to do nothing, even though WhatsApp is connected and normal DMs work.

## Root cause to check

Hermes WhatsApp may be paired in `self-chat` mode. In that mode the bridge historically accepted Semyon's own messages in his self-chat DM, but skipped `fromMe` messages in groups before the Python gateway saw them.

Look for bridge logic like:

```js
if (msg.key.fromMe) {
  if (isGroup || chatId.includes('status')) continue;
}
```

That makes WhatsApp Community groups invisible when Hermes is using Semyon's own number.

## Durable fix pattern

Adjust the self-chat bridge intake so:

1. Status/broadcast chats are still ignored.
2. `bot` mode still skips all `fromMe` echo-backs.
3. `self-chat` mode accepts `fromMe` group messages.
4. Non-group `fromMe` messages are still limited to the true self-chat DM.
5. Agent echo-backs are filtered later using reply prefix / recently sent IDs.
6. The Python adapter still enforces `group_policy` and `group_allow_from`.

Known-good shape:

```js
if (msg.key.fromMe) {
  if (chatId.includes('status')) continue;

  if (WHATSAPP_MODE === 'bot') {
    continue;
  }

  if (!isGroup) {
    const myNumber = (sock.user?.id || '').replace(/:.*@/, '@').replace(/@.*/, '');
    const myLid = (sock.user?.lid || '').replace(/:.*@/, '@').replace(/@.*/, '');
    const chatNumber = chatId.replace(/@.*/, '');
    const isSelfChat = (myNumber && chatNumber === myNumber) || (myLid && chatNumber === myLid);
    if (!isSelfChat) continue;
  }
}
```

## Config pattern

For one Hermes profile with persona-flavoured chats, do not invent separate OpenClaw-style config. Use WhatsApp group allowlisting and channel prompts:

```yaml
whatsapp:
  bridge_port: 3010
  group_policy: allowlist
  group_allow_from:
    - 120363425946976632@g.us  # General
    - 120363424689092728@g.us  # Chuck
    - 120363411141544642@g.us  # Theo
    - 120363407856354918@g.us  # Camille
    - 120363425108910720@g.us  # Eidhne
    - 120363407502633367@g.us  # R2D2
  free_response_chats:
    - 120363425946976632@g.us
    - 120363424689092728@g.us
    - 120363411141544642@g.us
    - 120363407856354918@g.us
    - 120363425108910720@g.us
    - 120363407502633367@g.us
  channel_prompts:
    120363425946976632@g.us: "General/root Hermes chat..."
    120363424689092728@g.us: "Chuck persona prompt..."
```

## Verification checklist

- `node --check scripts/whatsapp-bridge/bridge.js`
- `hermes config check`
- Confirm `whatsapp.group_policy`, `group_allow_from`, `free_response_chats`, and `channel_prompts` load into gateway config.
- Restart the gateway from outside the running gateway process, or schedule a delayed user-systemd restart so the current reply can deliver first.
- After restart, send a fresh message into one of the WhatsApp Community groups and check `~/.hermes/logs/gateway.log` for an inbound `platform=whatsapp` group message.

## Scope caveat

This creates one Hermes gateway/profile with per-chat persona prompts. It feels like separate Chuck/Theo/Camille/etc. chats, but it is not hard process isolation. For true isolated agents, use separate Hermes profiles or a kanban/dispatcher pattern.
