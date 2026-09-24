---
name: job-applications
description: Use this skill when doing a job application.
metadata:
  harnesses: [claude, codex]
---

# Job applications

Work only within the user's requested application scope. This skill does not authorize unsolicited applications. Apply `unslop` to the writing.

## Gather and check evidence

- Read instructions and inspect existing changes in `~/code/owned/career/cv`. Read `applications/README.md` for dated personal context and the prior application record. Preserve submitted variants and unrelated work. Portfolio sources usually live in `~/code/owned/career/portfolio`.
- Establish the exact employer, role, dates, location, recruiter and application stage. Search relevant Gmail threads, attachments, laptop Downloads, supplied Seol pages and employer documents. Use the relevant access skills. Keep searches scoped.
- Check actual programme PDFs before relying on generic web pages. A failed web search does not prove a claim is unsupported. Use memories and old threads as leads, then verify current facts.
- Extract the chosen CV's text and compare with current source modules and user corrections. Autofill and filenames do not establish freshness. Recheck study year, grades, positions, dates and project claims. Never infer citizenship, work authorization or sensitive demographic answers.
- Match the cover letter to the CV without rewriting the CV unless asked. Refer to selected projects and explain their personal meaning instead of repeating a technology list. Separate documented employer practices from impressions. Never invent motivation or inflate experience.

## Tailor the CV carefully

Choose the most relevant current CV variant before editing. When tailoring is requested, select and order existing, supported projects and skills to fit the role. Correct stale facts from verified sources and make small wording changes where they help. Preserve the factual meaning, the user's voice and historical submitted copies. Do not add technologies, metrics or responsibilities merely because the advert mentions them. Explain what changed and share the resulting PDF for review.

In the Rent the Runway session, the main CV action was replacing the stale autofilled PDF with an existing targeted version, not rewriting the CV. The letter then added personal context to the same projects. See the application record for the actual revisions.

## Get the user's voice

Reuse confirmed personal answers when relevant. Ask focused questions where context is missing. Five useful prompts from the first application were:

1. What actually appeals to you about this role, company or location?
2. What specific project moment did you enjoy, and why?
3. What do you want to learn beyond your own projects?
4. What would teammates say about working with you, including something you improved?
5. What should the recruiter understand that the CV does not show?

Do not ask all five again if existing answers suffice. Keep concrete experiences and believable enthusiasm. Avoid stock praise, invented lessons and phrases such as "a big draw". Be candid about artificial wording. Preserve approved passages and make targeted revisions when requested.

## Prepare the review copy

Semyon's preference is a human, one-page TeX letter, with the PDF shared for review. Use repository build conventions. Start with a plain date and role heading, without a decorative top bar. Address the actual recruiter by name when known. Sign off "Le meas," then "Semyon Fox", with contact details below the signature. Current user instructions override these preferences.

Compile, check extracted text and page count, and render the PDF to inspect spacing, clipping and signature. Share PDF and TeX local links before attaching when review was requested. Do not publish application files publicly without authorization.

## Enter the careers portal

This workflow covers the whole requested application: following the recruiter or employer link, entering the careers portal, opening the correct vacancy or existing application, filling each section, attaching documents, preparing replies and presenting everything for review.

Verify the employer and destination before entering personal information. Prefer the existing signed-in session and resume an existing application rather than creating a duplicate. If login, MFA or account creation needs the user's involvement, ask for that specific step. Do not inspect stored credentials or bypass authentication. Do not create an account, accept binding terms or make other permanent changes before the user has reviewed and authorized them.

Inspect all steps, including profile details, education, experience, screening questions, availability, eligibility and attachments. Check whether Next or Save only saves a draft or also sends information. Treat unclear actions as unresolved until their effect is established. A portal may autosave or upload files to the employer before final submission; do not describe such work as local-only. Flag that behavior when it affects the user's requested review boundary.

## Fill and verify

Use `device-fleet` for laptop access. Work in the existing authenticated browser. Discover current display, window and controls rather than reusing old coordinates, tab numbers or session IDs. Ask the user to unlock a locked session. Stop when asked to hold.

Review the entire form, including offscreen fields and inherited attachments. Use accurate student status rather than inventing an employer. Do not silently reuse unverified sensitive disclosures. Ask for required unknown answers and leave optional unknown disclosures unanswered where possible.

Identify each approved source file, use a clear upload filename, compare hashes when copying between machines, upload through the correct control, and verify the displayed filename after completion. Inspect actual PDF content too. Remove stale attachments. Allow delayed UI updates to settle before repeating actions.

## Respect authorization and verify the outcome

Default to preparation and drafts. Before final submission, email sending or another permanent action, let Semyon see and verify the complete result and obtain authorization for that action. Present the final CV and cover letter, form answers or a readable review of them, attachment filenames, and each email's recipient, subject and body. Identify any unanswered fields or checks that could not be completed. Do not treat a general request to help with an application as permission to submit it.

Track application submission and email sending separately. A request not to submit or send remains in force until the user overrides it. Wording approval alone does not override it. A later explicit "attach and submit application" authorizes that application submission without another permission request, but does not authorize sending email drafts. Respect applicable authorization already given in the conversation.

Before authorized submission, verify required fields, role and approved attachments. Submit once and inspect the confirmation. If the outcome is ambiguous, check status or receipt before retrying. Report the evidence rather than assuming success.

Keep interview acknowledgements, requests for more information and completion replies as drafts for review. Draft them in Semyon's voice, using a named greeting when appropriate, a direct acknowledgement or answer, and his preferred sign-off. Do not send automatically after the application is submitted.

For email drafts, inspect existing drafts and preserve user edits. Reply in the correct thread, verify recipient and relevant CCs, and use the real recruiter instead of a no-reply sender. Keep claims accurate: do not say "submitted" before submission or claim a calendar entry exists without evidence. Send only with applicable authorization.

Record the date, role, final document paths, important corrections, authorization and observed outcome in the career repository. Omit private applicant links, tokens, demographics and unnecessary inbox details. Documentation does not authorize committing, pushing or publishing.
