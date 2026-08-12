---
name: portfolio-blog-writing
description: "Use when write, revise, and review Semyon Fox's semyon.ie blog posts in the established first-person builder-journal voice."
version: 1.0.0

metadata:
  harness: [hermes]
---

# Portfolio Blog Writing

Use this skill whenever drafting, revising, planning, or critiquing a post for Semyon Fox's personal site, **semyon.ie**.

## Source of truth

Read the local Markdown corpus before making style claims or drafting:

```text
~/code/personal/portfolio/src/content/blog/
```

Posts use YAML frontmatter followed by Markdown. Inspect the current corpus, especially closely related posts, rather than relying on rendered-page extraction or memory. Existing writing may evolve; the local files are authoritative.

## Core voice

The blog is a **first-person builder's journal**, not a generic technical blog, tutorial catalogue, LinkedIn post, or academic essay.

- Start from something that genuinely happened: a failure, annoyance, constraint, curiosity, event, or decision.
- Write plainly, conversationally, and with confidence without pretending certainty.
- Put personal stakes and real context before abstract explanation.
- Let technical details explain a lived experience; do not make the post an excuse to recite concepts.
- Use Irish/student-builder naturalness where it fits: restrained phrases such as “class,” “I’ll be honest,” “a mixed bag,” or “far too much” are welcome when authentic.
- Allow short, dry humour, but use it as a release valve—not a performance. One sharp line is often enough.

Good voice anchors from the corpus:

- “I’m a vibe coder. There, I said it.”
- “I did not start self-hosting because of privacy. I started because I had a broken laptop and not much money.”
- “So I did.”
- “A progress bar is not evidence.”
- “It is a mixed bag, but it is my mixed bag.”

Do not imitate these lines mechanically. Preserve the underlying directness and ownership.

## Recurring story structure

The dominant arc is:

> **curiosity or need → attempt → complication / limitation → practical lesson**

Use this for technical, event, personal, and opinion pieces.

A strong technical post usually follows:

1. **Concrete opening:** the exact moment, problem, or outcome.
2. **Plain-English baseline:** what the original approach/system did and why it seemed reasonable.
3. **Pressure point:** what made it inadequate—scale, friction, failure, repeat work, latency, cost, or a real constraint.
4. **Change:** the improved design/algorithm/tool, introduced only after readers understand why it matters.
5. **Evidence:** a measured result, operation count, visible behavioural change, or worked example. Use real numbers only when they substantiate the point.
6. **Trade-off:** complexity, memory, time, maintenance, edge cases, cost, or where the simple solution was still enough.
7. **Grounded close:** the transferable lesson, without a grand manifesto.

For an algorithms/performance post specifically, frame it as a real behaviour that became wasteful or slow—not “here is an algorithm I learnt.” Explain the naïve approach in ordinary language before naming Big-O notation, a data structure, or the algorithm. The reader should understand the pain before the vocabulary arrives.

## Editorial principles

### Be grounded

- Use specific facts from the work: files, systems, observed behaviour, real constraints, verified measurements, or a bounded worked example.
- Numbers support the story; they do not replace it. Avoid benchmark theatre and invented precision.
- Connect to prior posts only when it adds useful continuity.
- State facts and conclusions proportionately. If something was not measured, say what was observed rather than manufacturing a result.

### Explain with judgement

The established writing values deliberate trade-offs:

- RAID is redundancy, not backup.
- A snapshot is not a separate backup.
- Self-hosting is not automatically cheaper.
- Faster AI work does not remove human responsibility.
- A more complex solution is not automatically a better one.

Do not write technology as universally good or bad. State what made the choice worthwhile in this situation, its cost, and where a simpler/hosted/manual approach remains sensible.

### Keep it readable

- Prefer short-to-medium paragraphs and descriptive `##` headings.
- Use `###` only where a longer post needs it.
- Define technical terms through the thing they change, not a dictionary entry.
- Use a short blockquote for a memorable principle when it earns its place.
- Use code blocks only for genuinely reusable, small commands/prompts; explain the surrounding decision.
- Add diagrams/images only when they clarify systems, flows, comparisons, or decisions. Supply precise alt text.
- Titles are specific and human: state the incident, decision, or tension. A deliberately provocative title is fine only when the post gives it nuance.

## Avoid

- Generic “In today’s fast-paced world…” introductions.
- Tutorial voice that assumes the reader wants a universal install guide.
- Academic/dissertation framing, excessive definitions, or Big-O notation before the reader understands the practical problem.
- Artificially polished corporate phrases, generic calls to action, or forced motivational endings.
- Overclaiming autonomy, performance, security, reliability, or scale.
- Hiding failures, uncertainty, or compromises; candid limitations build credibility.
- Turning every paragraph into a joke, a list, or an AI-sounding rhetorical question.

## Metadata and repo discipline

Preserve the existing content shape:

```yaml
---
title: 'Specific, human title'
date: 'YYYY-MM-DD'
author: 'Semyon Fox'
description: 'One-sentence accurate summary.'
tags: ['Relevant', 'Specific', 'Tags']
---
```

- Match quote and list style of neighbouring posts where practical.
- Keep the description accurate, direct, and distinct from the title.
- Use a small, relevant tag set; favour existing taxonomy when it fits.
- Use internal links such as `/blog/<slug>` for relevant earlier writing.
- Do not modify unrelated posts, site styling, or publishing configuration while drafting unless explicitly asked.

## Review checklist

Before presenting a draft or making a repo edit, verify:

- [ ] The opening is a real personal/system/event premise, not a textbook introduction.
- [ ] The narrative explains why the subject mattered before explaining how it works.
- [ ] Technical claims, numbers, and results are sourced from supplied material or verified local evidence.
- [ ] The naïve approach and the improvement are understandable in plain English.
- [ ] Trade-offs and limits are explicit.
- [ ] Tone remains candid, concise, and owned by Semyon.
- [ ] Headings, frontmatter, links, and asset alt text match the site’s Markdown conventions.
- [ ] The ending is concrete and restrained rather than inspirational filler.
