# Interview prep kits

Use this reference when Semyon asks for urgent interview preparation, especially technical/software/SRE roles.

## Goals

Produce a practical kit Semyon can actually use before walking into the interview:

- one concise narrative spine;
- polished answers for likely questions;
- a STAR project story grounded in real repo/project facts;
- technical cheat sheet for the role;
- demo/diagram guidance;
- last-minute drill card;
- optional small side project only if it is quick and role-relevant.

## Workflow

1. Read the user's handoff/job notes if provided.
2. Verify role/company/team signals from current public sources when useful, but do not overfit or pretend to know internal details.
3. Inspect relevant local projects/repos before writing project answers. Ground claims in actual files, stack, scripts, tests, and architecture.
4. Create a folder under `~/interview-prep/<company-or-role>/` with markdown files instead of dumping everything into chat.
5. Include:
   - `README.md` — overall strategy/spine;
   - `01-<project>-star.md` — main STAR answer;
   - `02-<domain>-cheatsheet.md` — role fundamentals;
   - `03-mock-interview.md` — likely questions + answers;
   - `04-architecture-diagram.md` — simple text diagram and talking points;
   - `05-last-minute-drill-card.md` — shortest review surface.
6. If a small side project is useful, build it in the prep folder and actually verify it runs. Prefer Docker/toolchain workarounds over giving unverified code when the local toolchain is missing.
7. Package the folder as a tarball if the chat surface supports attachments.

## Style

Semyon responds best to direct, practical coaching: concise, mildly funny, and confidence-building without corporate fluff. Avoid generic advice. Do not make him sound like he is overselling expertise he does not have.

Good positioning for intern/SRE interviews:

> I build real things, I debug them, I learn fast, and I understand that production software needs observability, safe deployment, and recovery — not just features.

## Pitfalls

- Do not rely only on the user's supplied notes if the relevant repo is available; inspect it.
- Do not create a live-demo dependency unless it is verified and robust; static screenshots/files are safer.
- Do not turn side projects into a rabbit hole. They are supporting evidence, not the main event.
- Do not persist environment-specific setup failures as durable facts. Capture the repeatable workaround only when it is generally useful, e.g. “use a Docker language image to verify a tiny side project when local compiler/toolchain is absent.”
