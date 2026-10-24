---
name: council
description: Use when the user asks for a council or standup, or a big decision with a lot of scope behind it needs deliberating.

metadata:
  harnesses: [claude, codex, opencode]
---

# Council

Get three models to work out a big decision together until they all agree on the best approach. No debate format and no roles. Everyone is trying to find the right answer.

Start each member with `delegate_task`. Check `orchestrator_capabilities` first and skip a missing model rather than swapping it.

- `claude-opus-5-5`, effort high
- `gpt-6.1-sol`, reasoning effort high (it defaults to low)
- `opencode/deepseek-v4.1-flash-free`, variant high, agent plan

1. Write one brief with the question, why it matters, constraints, what's ruled out and where the evidence is. Members can't see this chat. Leave out secrets and private data because DeepSeek's free tier may keep prompts.
2. Send it to all three separately. Ask for their answer, the evidence they actually checked, a plan and what would change their mind. Tell them not to edit anything.
3. Send each one all three answers, labelled A, B and C. Each member checks the others' claims, gives them feedback with proof, and responds to the feedback on its own answer. Then it keeps or changes its answer. Being outnumbered isn't a reason to change.
4. Repeat with the latest answers and feedback until all three agree on the best approach. If they're still split after four rounds, take the split to the user.
5. Check the claims the agreed answer rests on yourself.

Lead with the agreed approach, then why it won and what each member added.
