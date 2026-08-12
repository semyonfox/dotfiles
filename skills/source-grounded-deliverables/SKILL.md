---
name: source-grounded-deliverables
description: "Use when extracting source-only instructions or prompts."
version: 1.0.0
created_by: agent

metadata:
  harness: [hermes]
---

# Source-grounded deliverables

Use this for videos, transcripts, documents, posts, or other named sources when the user wants a faithful extraction rather than a general recommendation.

## Provenance first

Before drafting, establish the requested evidence boundary:

- **Source says** — direct quotation or a faithful, clearly marked condensation of the source.
- **Source-derived synthesis** — reorganised or shortened material that does not add a new claim.
- **Local finding** — fact obtained by inspecting the user's files, configuration, or environment.
- **Recommendation / general knowledge** — the agent's judgement beyond the source.
- **Web finding** — fact obtained from a web source beyond the named source.

If the user asks for source-only output, do not add recommendations, general practice, local findings, or web research into the deliverable. If structural metadata is required to make an artifact usable (for example a skill name or trigger description), label it as structural rather than source wording.

## Workflow

1. Read or obtain the complete requested source, not a partial summary or substitute source.
2. Locate the exact relevant passages and preserve timestamps, section markers, or citations where available.
3. State whether the requested output is verbatim, a source-faithful condensation, or a recommendation based on the source.
4. For copy-paste text, give only the requested artifact when the user asks for a plain prompt. Do not preface it with explanation or provenance labels unless requested.
5. When turning material into a reusable artifact, retain source wording where practical and separate any unavoidable non-source material:
   - frontmatter/names/links needed by the artifact;
   - implementation-specific substitutions needed for the user's environment;
   - recommendations or safety additions.
6. Verify the final text against the cited passage before saying it is exact. Never call a synthesis “exactly as the source says.”

## Pitfalls

- Do not present an organised synthesis as a verbatim transcription.
- Do not quietly mix source claims with generic engineering advice.
- Do not infer a source's system design from a brief mention; distinguish what it explicitly says from a recommendation for the user's setup.
- Do not use web sources to fill gaps in a source-only request.
- Do not overwrite an existing user workflow/skill merely because a source suggests a different pattern; create a separate source-grounded artifact or ask for an explicit migration decision.

## Delivery conventions

- Use short labels such as **Video says**, **Local finding**, and **My recommendation** when multiple evidence types are present.
- If the user corrects an output because they want the literal source rather than explanation, switch immediately to the requested plain format.
- Record source title and precise passage range in a comment or reference when creating a durable artifact, but keep the operational body readable.

## Verification checklist

- [ ] The named source—not a substitute—was used.
- [ ] Each non-source addition is disclosed or excluded.
- [ ] “Exact” is used only for text checked against the source.
- [ ] A plain-prompt request received plain copy-paste text.
- [ ] Durable artifacts identify their source passage and structural additions.
