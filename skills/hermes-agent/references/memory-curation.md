# Archived source skill: `memory-curation`

Preserved after consolidation into `hermes-agent`. Use the umbrella first; consult this for detailed recipes.

---

---
name: memory-curation
description: Curate durable Hermes memory from user-provided profiles, corrections, preferences, and stale-memory cleanup. Use when the user asks to remember/ingest information, update profile context, or review memories.
---

# Memory Curation

Use this skill when the user asks to ingest personal information, update memories, remember preferences, correct stale profile facts, or clean up durable context.

## Goals

- Save durable, high-signal facts that will still be useful later.
- Avoid bloating memory with full dumps, temporary status, or stale task logs.
- Preserve sensitive context carefully and anonymously where needed.
- Be transparent about what was saved versus merely processed.

## Workflow

1. **Identify the source shape**
   - If the payload is truncated or malformed, ask for the full content before saving.
   - If the user provides a long profile/export, treat it as source material, not something to store verbatim in memory.

2. **Extract durable facts**
   Save facts about:
   - Identity and names to use or avoid.
   - Stable personal context: education, location, role, long-running projects.
   - Preferences for style, writing, workflows, teaching, and assistant behaviour.
   - Long-running infrastructure/project conventions.
   - Sensitive context that prevents future mistakes.

3. **Discard or avoid saving**
   - One-off task progress, PR/issue/commit identifiers, exact counts that change often, and transient tool failures.
   - Large verbatim biographies or project dumps.
   - Claims that will likely be stale within a week.
   - Private/sensitive details unless they prevent harmful future behaviour, and then keep them concise.

4. **Handle assistant/bot naming preferences**
   - First disambiguate the target of the rename from the user's wording and context:
     - **Platform bot/account/server nickname**: “change this bot’s name”, “bot name”, Discord/Telegram/server wording. Treat this as a platform admin/config task, not a durable assistant identity preference.
     - **Conversational self-label/persona**: “call yourself X”, “from now on you are X”, explicit memory/persona wording. Only then save a compact memory entry if it will help future sessions.
   - Do **not** save a memory entry for a platform bot rename unless the user explicitly says they also want future conversations to use that name. If you saved one prematurely and the user corrects you, remove it immediately.
   - Distinguish **conversational identity** from **platform account/server nickname**. You can remember and use a requested self-label in replies; changing a Discord/Telegram/etc. account name or server nickname is a platform admin/config action and may require external permissions.
   - Avoid overclaiming: say clearly whether you changed memory/conversational behaviour, platform configuration, or both.

5. **Clean stale memory when appropriate**
   - Remove obvious junk, duplicated promoted fragments, stale contradictions, or old assistant-output artifacts.
   - Prefer replacing stale entries with concise canonical facts rather than accumulating conflicts.

6. **Confirm precisely**
   - Say what categories were saved.
   - If the user asks whether everything was saved, be honest: memory stores the durable compressed version, not a verbatim archive.
   - Offer to save the full source separately as a local reference file or note if the user wants a canonical long-form archive.

## User-specific handling for Semyon

When ingesting Semyon's profile context:

- Treat **Semyon Fox** as the canonical current identity.
- Treat adoption/origin-name context as sensitive; do not surface casually.
- Preserve current project priority order when supplied.
- Avoid hard-coding fast-changing homelab counts or transient project states.
- Professional writing preferences matter: direct, grounded, no corporate slop, no emojis, avoid em dashes, return full revised versions during editing.

## Pitfalls

- **Do not imply a full profile was saved verbatim** unless it actually was written to a file/note. Say "I saved the durable summary" instead.
- **Do not put giant profile dumps into memory.** Memory is for compact durable steering context.
- **Do not save stale assistant-generated fragments.** Clean them up if they crowd out better user-provided facts.
- **Do not over-summarize sensitive identity corrections.** The point is to prevent future accidental misuse.

## References

- `references/memory-curation-references-profile-ingestion-2026-06-05.md` captures the lesson from ingesting a long canonical user profile: compress into memory, clean stale conflicts, and explicitly distinguish durable memory from verbatim archival storage.
