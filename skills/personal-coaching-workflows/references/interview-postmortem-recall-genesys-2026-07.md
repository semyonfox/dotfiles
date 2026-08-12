# Genesys interview postmortem recall — July 2026

Use as session-specific context when Semyon asks to recall what happened in the Genesys interview or wants to turn the interview into prep notes.

## Actual remembered interview topics/questions

Semyon reported after the interview that it went well overall, but he was caught by some textbook OOP vocabulary questions:

- **Class vs object**
  - His rough answer: object is the data; class is the structure it takes.
  - Clean answer: class is the blueprint/type definition; object is a concrete instance with its own state/values in memory and behaviour via the class.

- **Overloading vs overriding**
  - He was fuzzy on this.
  - Clean answer: overloading = same method name with different parameter lists; overriding = subclass provides its own implementation of a parent method.

- **How many instances can there be of a class?**
  - His answer was mostly OK: depends on language/runtime/hardware; practically limited rather than conceptually fixed.
  - Clean answer: usually no per-class fixed limit; limited by memory, object size, runtime/GC overhead, address space, and implementation constraints.

- **HTTP status codes**
  - He got 200, 3xx redirects, 4xx client errors mostly right.
  - He misclassified 5xx as auth-ish; correct: 5xx = server-side errors. Auth is mostly 401/403 in 4xx.

- **AI as an assistant / developer replacement**
  - He felt he handled this well.
  - Strong framing: AI speeds up capable developers, but does not remove understanding, review, testing, responsibility, or company data/security constraints.

## Positive signals he reported

- Interviewer played games on his website.
- Interviewer said his GitHub was very impressive.
- They engaged with his actual work rather than only rehearsed answers.
- At the end he asked if there was anything else they wanted clarified; they said all good.

## Coaching interpretation

Frame this as: not flawless, but strong. The weak spots were vocabulary/refresher gaps, not evidence that he cannot build. The proof-of-work — GitHub, website, projects, AI-native maturity — landed well.

Useful short friend-summary:

> Interview went well. Website/GitHub landed strongly. I handled AI well. I mostly got HTTP status codes except 5xx. I tripped on OOP basics — class/object, overload/override — but those are fixable vocabulary gaps, not a sign I can’t build. Overall: not flawless, but strong. Proof-of-work carried hard.
