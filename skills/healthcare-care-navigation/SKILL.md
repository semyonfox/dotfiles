---
name: healthcare-care-navigation
description: "Use for healthcare referral and appointment forms."
version: 1.0.0

metadata:
  harness: [hermes]
---

# Healthcare Care Navigation

## Purpose

Handle practical care access: identify the correct clinician/service, find the official appointment or referral route, extract exactly what is required, and prepare a concise factual enquiry. This is administrative support, not diagnosis or treatment advice.

## Workflow

1. **Identify the exact destination first.** Ask for the clinician, clinic, speciality, and city if known. Search the named provider’s official site before using directories or generic advice. When a named clinician offers an official direct appointment form, prefer and verify that route before preparing a generic hospital-group appointment request; it is generally shorter and routes directly to the intended practice.
2. **Inspect the actual official page/form.** Record literal required fields, optional fields, consent language, privacy/retention statement, clinic location/days, contact details, and any preferred date control.
3. **Separate the route correctly.** Confirm whether it is a direct appointment enquiry, GP referral submission, separate GP letter/test-result transfer, or a service needing insurer/HSE authorisation. Never infer a referral requirement merely because the user has already seen a GP.
4. **Collect the minimum needed.** For an allergy or similar specialist enquiry, get contact details and preferred timing; symptom pattern; prior tests and results; suspected triggers; relevant conditions and treatments tried; and whether the GP will send a referral letter/results separately. If a GP simply advised seeing a specialist and testing found no specific trigger, record that precisely; do not imply that a formal referral letter or a diagnosis exists.
5. **Verify the provider’s current web identity.** A legacy clinic URL may redirect to a parent hospital group. Follow the official redirect, find the named clinician’s official profile, then inspect the actual appointment form. Use the profile to verify specialty, location, availability, and direct contact details; use the form as the authority for submission fields and referral-upload rules. When the user names a clinician, select that clinician in the form if the official options allow it; do not silently replace the intended clinician with a generic service route.
6. **Draft in the patient’s voice.** Start with the user’s own plain-language account and edit only enough for clarity. Do not substitute formal clinical language when the user wants a natural note: retain wording such as “my GP recommended I see you” rather than “I was advised to seek specialist assessment.” State results factually and without diagnosis.
7. **Draft, don’t submit by default.** Preserve uncertainty: say a test was positive or inconclusive rather than naming an unconfirmed allergy. Obtain explicit user approval before submitting a medical form or sending health information. CAPTCHA challenges must be completed by the user; never bypass, simulate, or claim to have completed one.
8. **Flag urgent symptoms cleanly.** If the user describes current breathing difficulty, throat/tongue swelling, collapse/faintness, or rapidly worsening widespread hives, advise urgent emergency care rather than continuing appointment administration.

## Output Standard

Lead with the verified route and a tight checklist of exact form fields. State what is known from the official page versus what still needs to come from the user. Do not bury the required information under generic health education.

## Pitfalls

- Searching generic “GP referral form” before establishing the named clinician produces irrelevant forms.
- Treating a web contact form as proof that it accepts referrals or uploaded medical records.
- Asking for exhaustive medical history when the actual form only needs a concise complaint summary.
- Sending an enquiry or disclosing medical details without clear user approval.
