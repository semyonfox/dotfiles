---
name: council
description: Use when the user asks for a council or standup, a big decision with a lot of scope behind it needs deliberating, or the user wants a change reviewed by three models until they agree.

metadata:
  harnesses: [claude, codex, opencode]
---

# Council

Get three models to work out a big decision or review a change together until they all agree. No debate format and no roles. Everyone is trying to find the right answer.

Start each member with `delegate_task`. Check `orchestrator_capabilities` first and skip a missing model rather than swapping it.

- `claude-opus-5-5`, effort high
- `gpt-6.1-sol`, reasoning effort high (it defaults to low)
- `opencode/deepseek-v4.1-flash-free`, variant high, agent plan

Members can't see this chat. Leave out secrets and private data because DeepSeek's free tier may keep prompts. Tell them not to edit anything. Stop after four rounds and take any split to the user.

## Decisions

1. Write one brief with the question, why it matters, constraints, what's ruled out and where the evidence is.
2. Send it to all three separately. Ask for their answer, the evidence they actually checked, a plan and what would change their mind.
3. Send each one all three answers, labelled A, B and C. Each member checks the others' claims, gives them feedback with proof, and responds to the feedback on its own answer. Then it keeps or changes its answer. Being outnumbered isn't a reason to change.
4. Repeat with the latest answers and feedback until all three agree on the best approach.
5. Check the claims the agreed answer rests on yourself.

Lead with the agreed approach, then why it won and what each member added.

## Code review

1. Brief each member with the diff command, the intent, what's out of scope and the checks you ran. Ask for findings with file and line, and a score out of 10.
2. Verify each finding yourself. Make the changes you agree with, then send the new diff for a fresh round. A full review pass is one round.
3. Continue until all three are satisfied. Fight scope creep: repeated reviews grow a change one cheap fix at a time, so decline nits and out-of-scope asks with a reason.

Report the rounds and scores in your reply. If a member gives no score, write `no score` and don't invent one:

```markdown
| Member | Round 1 | Round 2 |
| --- | --- | --- |
| Claude Opus | 7/10 | 9/10 |
| GPT Sol | 8/10 | 10/10 |
| DeepSeek Flash | 7/10 | 9/10 |
```

Put that table in a PR description only when the repo has `attribution: on`. Edit the description rather than posting a comment.
