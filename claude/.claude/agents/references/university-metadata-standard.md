# University Metadata Standard

## Goal

Make university notes easy to search, filter, graph, and cross-link without over-tagging.

This standard is the source of truth for human edits, AI edits, note atomization, link weaving, exam indexing, and metadata cleanup in `University/`.

## Core Rule

Properties carry meaning. Tags create broad graph/filter nodes. Links connect notes.

Use all three:

- Properties/frontmatter for structured search and Dataview.
- Controlled tags for graph-visible nodes and broad filters.
- Wikilinks for actual relationships between notes and sections.

Do not use tags as a dumping ground for every keyword. A `topic/...` tag should be useful as a graph node.

## Frontmatter Template

Use this template for real learning notes, revision notes, exam notes, and meaningful resources:

```yaml
---
title: "Big O and Algorithm Analysis"
module: ct102
module_name: algorithms and information systems
year: 1
semester: 2
type: lecture
lecture_number: 2
week: 3
lecturer: ""
status: processed
exam_relevance: critical
topics:
  - algorithm-analysis
  - big-o
subtopics:
  - time-complexity
  - space-complexity
  - worst-case
  - asymptotic-notation
tags:
  - university
  - module/ct102
  - year/1
  - semester/2
  - type/lecture
  - status/processed
  - exam/critical
  - topic/algorithm-analysis
  - topic/big-o
aliases:
  - Big O
  - O notation
  - asymptotic notation
related:
  - "[[Time Complexity]]"
source: my-notes
---
```

Minimal administrative notes, Canvas dumps, marks pages, and raw indexes do not need `topics` or `subtopics` unless they contain real learning content:

```yaml
---
title: "Canvas Modules"
module: ct230
module_name: database systems
year: 2
semester: 1
type: canvas
status: raw
tags:
  - university
  - module/ct230
  - year/2
  - semester/1
  - type/canvas
  - status/raw
source: canvas
---
```

## Field Definitions

| Field | Required | Format | Use |
| --- | --- | --- | --- |
| `title` | Recommended | Human title | Search/display title. |
| `module` | Yes for module notes | Lowercase code, e.g. `ct230` | Machine-readable module key. |
| `module_name` | Recommended | Lowercase readable name | Human-readable course name. |
| `year` | Yes | Number, e.g. `1`, `2` | Enrollment/study year. |
| `semester` | Recommended | Number, e.g. `1`, `2` | Teaching semester when known. |
| `type` | Yes | Controlled value | What kind of note this is. |
| `lecture_number` | Lecture only | Number or quoted range | Lecture ordering. |
| `week` | Optional | Number | Week ordering when useful. |
| `lecturer` | Optional | Text or list | Source/context, not a tag. |
| `status` | Yes | Controlled value | Processing state. |
| `exam_relevance` | Learning notes | Controlled value | Exam importance as property. |
| `topics` | Learning notes | List of kebab-case values | Broad concepts for structured search. |
| `subtopics` | Optional | List of kebab-case values | Detailed concepts that should not clutter the graph. |
| `tags` | Yes | Controlled tags | Graph/filter labels. |
| `aliases` | Optional | Search phrases | Alternate names and spellings. |
| `related` | Optional | Wikilinks | Related notes/concepts. |
| `source` | Recommended | Controlled value | Where the note/content came from. |

Allowed `type` values:

```text
lecture
lab
assignment
overview
exam-index
exam-summary
revision
canvas
project
resource
```

Allowed `status` values:

```text
raw
processed
complete
review
todo
```

Allowed `exam_relevance` and `exam/...` values:

```text
critical
relevant
reference
unknown
```

Allowed `source` values:

```text
my-notes
canvas
slides
exam-paper
eidhne-reference
generated
mixed
```

## Tag Rules

All tags must be:

- lowercase
- hyphen-separated where needed
- unquoted in YAML
- written without `#` in YAML frontmatter
- free of spaces
- free of underscores
- free of uppercase characters
- max one `/`

Valid:

```yaml
tags:
  - university
  - module/ct2108
  - year/2
  - semester/1
  - type/lecture
  - status/processed
  - exam/critical
  - topic/big-o
  - topic/osi-model
```

Invalid:

```yaml
tags:
  - "#topic/BigO"
  - topic/Big_O
  - topic/big o
  - course/CT2108
  - year/2nd
  - week-3
```

Only these tag categories should be used for university notes:

```text
university
module/[code]
year/[number]
semester/[number]
type/[note-type]
status/[state]
exam/[relevance]
topic/[controlled-topic]
```

Deprecated formats:

- `course/...` -> use `module/...`
- `year/1st` -> use `year/1`
- `year/2nd` -> use `year/2`
- quoted `"#topic/..."` -> use unquoted `topic/...`
- raw topic tags such as `big-o` -> use `topic/big-o` only if graph-worthy, otherwise use `subtopics`

## Topic Vs Subtopic

Use `topics` for broad concepts that help find a note across modules and years.

Use `subtopics` for detailed ideas, techniques, examples, protocols, commands, keywords, and terms that are useful for search but too small for graph nodes.

Good `topic/...` tags:

```yaml
- topic/big-o
- topic/gdpr
- topic/osi-model
- topic/sql
- topic/normalisation
- topic/recursion
- topic/sorting
- topic/probability
- topic/boolean-algebra
```

Too granular as graph tags:

```yaml
- topic/ipv4-header-checksum
- topic/week-3-slide-17
- topic/java-private-keyword
- topic/select-star-from-table
```

Move granular concepts to `subtopics`:

```yaml
topics:
  - networks
  - osi-model
subtopics:
  - network-layer
  - routing
  - ipv4
  - ipv6
  - icmp
  - arp
tags:
  - topic/networks
  - topic/osi-model
```

A normal note should have `1-3` `topic/...` tags. Use more only when the note genuinely bridges several major concepts, and mark `status: review` if uncertain.

## Graph Rules

Obsidian graph nodes come from notes and tags. Properties are searchable and queryable, but plain property values are not graph nodes by themselves.

Use graph tags deliberately:

- `module/...` shows module clusters.
- `type/...` shows note-type clusters.
- `topic/...` shows concept clusters.

Do not create standalone topic notes by default. Create topic notes only when a concept becomes a major long-term hub that needs its own explanation or index.

## Eidhne's Notes Policy

Do not edit anything under:

```text
eidhne/
```

Allowed:

- Read Eidhne's notes.
- Link from your notes to Eidhne's notes.
- Use them as additional material.

Forbidden:

- Adding frontmatter to Eidhne's notes.
- Retagging Eidhne's notes.
- Renaming or moving Eidhne's files.
- Creating backlinks inside Eidhne's notes.

Preferred format in your notes:

```markdown
## Additional Material

### Eidhne
- [[eidhne/college_vault/CT102/algorithmic_analysis|Algorithmic analysis notes]]
```

## Dataview Examples

All notes for a module:

```dataview
TABLE type, lecture_number, topics, status
FROM #module/ct230
SORT type ASC, lecture_number ASC, file.name ASC
```

All notes for a graph topic:

```dataview
TABLE module, lecture_number, topics, subtopics
FROM #topic/big-o
SORT year ASC, module ASC, lecture_number ASC
```

Find a subtopic even if it is not a graph tag:

```dataview
TABLE module, lecture_number, topics, subtopics
FROM "university"
WHERE contains(subtopics, "ipv4")
SORT module ASC, lecture_number ASC
```

Find notes needing review:

```dataview
TABLE module, type, topics, subtopics
FROM "university"
WHERE status = "review" OR contains(tags, "status/review")
SORT module ASC, file.name ASC
```

Exam-critical notes:

```dataview
TABLE module, lecture_number, topics
FROM #exam/critical
SORT module ASC, lecture_number ASC
```

## Validation Checklist

Before committing a new or transformed university note:

- [ ] Frontmatter exists for real university notes.
- [ ] `module` is lowercase, e.g. `ct213`.
- [ ] `year` is numeric, e.g. `1` or `2`.
- [ ] `semester` is numeric when known.
- [ ] `type` is one of the allowed values.
- [ ] `status` is one of the allowed values.
- [ ] `exam_relevance` is one of the allowed values when present.
- [ ] Tags are lowercase, hyphen-separated, and unquoted.
- [ ] Tags do not contain `#`, spaces, underscores, or uppercase.
- [ ] Tags use only approved categories.
- [ ] Learning notes have `topics`.
- [ ] Detailed concepts are in `subtopics`, not noisy graph tags.
- [ ] Normal notes have no more than `1-3` `topic/...` tags unless justified.
- [ ] Internal references use wikilinks.
- [ ] Eidhne's notes are linked only as read-only additional material.

## Examples

### Lecture

```yaml
---
title: "Network Layer - Routing and IP"
module: ct2108
module_name: networks and data communication
year: 2
semester: 2
type: lecture
lecture_number: 6
week: 6
status: processed
exam_relevance: critical
topics:
  - networks
  - osi-model
subtopics:
  - network-layer
  - routing
  - ipv4
  - ipv6
  - icmp
  - arp
tags:
  - university
  - module/ct2108
  - year/2
  - semester/2
  - type/lecture
  - status/processed
  - exam/critical
  - topic/networks
  - topic/osi-model
source: my-notes
---
```

### Assignment

```yaml
---
title: "Assignment 2 - Rainbow Tables"
module: ct2110
module_name: digital security and media
year: 2
semester: 1
type: assignment
status: complete
exam_relevance: relevant
topics:
  - cryptography
  - password-security
subtopics:
  - rainbow-tables
  - hash-functions
  - password-cracking
tags:
  - university
  - module/ct2110
  - year/2
  - semester/1
  - type/assignment
  - status/complete
  - exam/relevant
  - topic/cryptography
  - topic/password-security
source: my-notes
---
```

### Exam Index

```yaml
---
title: "CT230 Exam Papers Index"
module: ct230
module_name: database systems
year: 2
semester: 1
type: exam-index
status: processed
exam_relevance: critical
topics:
  - sql
  - normalisation
  - database-design
subtopics:
  - ddl
  - dml
  - er-models
  - relational-algebra
tags:
  - university
  - module/ct230
  - year/2
  - semester/1
  - type/exam-index
  - status/processed
  - exam/critical
  - topic/sql
  - topic/normalisation
  - topic/database-design
source: exam-paper
---
```

### Canvas Or Raw Resource

```yaml
---
title: "Canvas Overview"
module: ct230
module_name: database systems
year: 2
semester: 1
type: canvas
status: raw
tags:
  - university
  - module/ct230
  - year/2
  - semester/1
  - type/canvas
  - status/raw
source: canvas
---
```
