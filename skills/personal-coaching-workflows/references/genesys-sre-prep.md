# Genesys SRE interview prep patterns

Session-specific reference from July 2026 Genesys Galway Service Resiliency/SRE prep.

## Conversational correction

Semyon explicitly pushed back on large answer dumps and asked for short answers, normal conversation, and quizzing. For interview prep, use tight back-and-forth coaching.

## Strong positioning

Brand:

> Practical systems builder.

Not:

- AI wizard
- homelab chaos creature
- frontend hater
- student comparing himself to other students

## Project selection

For “most proud”:

- Lead with Uisce/swim club management if that is emotionally true.
- Frame it as the origin of his architectural understanding.

For “most relevant to SRE/Service Resiliency”:

- Lead with OghmaNotes.
- Emphasize backend, auth, Postgres, Redis, workers/queues, deployment, Amplify/serverless constraints, observability/recovery.

## High-value incident story

OghmaNotes on Amplify/serverless:

- Long-running LLM streams/imports worked locally.
- Production/serverless runtime limits caused partial/stopped behavior.
- Logs were not enough; timing logs and reproduction showed the pattern.
- Fix: move long work out of web request path into queue/worker/background function, with durable DB progress/status and polling.
- Lesson: local success does not prove production readiness.

## Polished answers/patterns

Why Genesys:

> I heard about Genesys through people who work here, and the feedback has been consistently positive. The Service Resiliency role stood out because it matches where my interests have been going: backend systems, deployment, debugging, and reliability.

AI usage:

> I use AI heavily in development to move faster: debugging, explaining unfamiliar concepts, generating boilerplate, comparing tradeoffs, and thinking through architecture. I think being good with AI tools is becoming a real engineering skill, but the value is knowing how to direct, review, and verify them — not blindly accepting output. For company work, I’d follow approved tooling and data policies, especially around private code.

Closing/feedback:

> Before we finish, is there anything in my background or answers that you’d like me to clarify?

> Do you have any advice on areas I should strengthen if I want to grow into this kind of SRE/platform engineering role?
