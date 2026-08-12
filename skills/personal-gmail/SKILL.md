---
name: personal-gmail
description: "Read, search, summarize, label, modify, or send Gmail for Semyon's personal Google accounts using local OAuth tokens."
version: 1.0.0
created_by: agent
related_skills:
  - personal-google-apis

metadata:
  harness: [hermes]
---

# Personal Gmail

Use this when Semyon asks to inspect, search, summarize, label/archive, draft, or send Gmail from his personal Google accounts.

Load `personal-google-apis` too only if you need account setup details, OAuth re-auth, Google Cloud API links, or PC/Helium browser fallback. For ordinary Gmail tasks, this skill should be enough. For a worked draft-editing/OAuth reauth pitfall, see `references/gmail-draft-update-oauth-2026-07.md`.

## Accounts

```text
personal       -> semyon.fox@gmail.com
foxscopegaming -> foxscopegaming@gmail.com
```

Old typo label `foscopegaming` may exist; prefer `foxscopegaming`.

Never use inactive `semyon@oghmanotes.ie` for current personal Gmail tasks unless Semyon explicitly asks about old Workspace/GAM cleanup.

## Safety posture

- Read/search/summarize is allowed when requested.
- Sending, deleting, archiving, marking read/unread, changing labels/filters/settings, or modifying mail requires explicit user intent.
- Before sending or modifying, state the account label and target action.
- Draft first unless Semyon clearly asks to send immediately.
- Do not paste raw tokens, refresh tokens, or huge private email bodies into chat.
- Prefer sender/subject/date/snippet unless Semyon asks for body details.

## Quick checks

```bash
gmail-whoami personal
gmail-whoami foxscopegaming
```

Expected identities:

```text
personal       -> semyon.fox@gmail.com
foxscopegaming -> foxscopegaming@gmail.com
```

## Python pattern

Use the dedicated venv if running standalone scripts:

```bash
~/.local/venvs/google-api/bin/python script.py
```

Boilerplate:

```python
from pathlib import Path
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

SCOPES = ["https://www.googleapis.com/auth/gmail.readonly"]
label = "personal"  # or "foxscopegaming"
token_path = Path.home() / ".hermes/google-personal/accounts" / label / "token.json"
creds = Credentials.from_authorized_user_file(str(token_path), SCOPES)
if creds.expired and creds.refresh_token:
    creds.refresh(Request())
    token_path.write_text(creds.to_json())

gmail = build("gmail", "v1", credentials=creds, cache_discovery=False)
```

## Useful read/search calls

Profile:

```python
profile = gmail.users().getProfile(userId="me").execute()
```

Labels:

```python
labels = gmail.users().labels().list(userId="me").execute().get("labels", [])
```

Search messages:

```python
msgs = gmail.users().messages().list(
    userId="me",
    q="from:example@example.com newer_than:30d",
    maxResults=10,
).execute().get("messages", [])
```

Read metadata/snippets:

```python
msg = gmail.users().messages().get(
    userId="me",
    id=msg_id,
    format="metadata",
    metadataHeaders=["From", "To", "Subject", "Date"],
).execute()
```

Read full message when needed:

```python
full = gmail.users().messages().get(userId="me", id=msg_id, format="full").execute()
```

## Gmail search syntax examples

```text
newer_than:7d
older_than:30d
from:person@example.com
subject:(invoice OR receipt)
has:attachment
label:inbox
-is:spam -is:trash
"exact phrase"
```

Combine them:

```text
from:github.com newer_than:14d -is:spam
(subject:invoice OR subject:receipt) newer_than:90d
has:attachment filename:pdf newer_than:1y
```

## Delivering travel tickets from email

When Semyon asks for a QR rail/transport ticket found in Gmail, treat the ticket itself as sensitive and deliver only to the requested private chat.

1. Search the booking confirmation and inspect its MIME parts. Do not assume a ticket PDF is attached.
2. If the email contains a signed booking-management link, open it in the browser and locate the official **Download QR Ticket** control. Do not change, cancel, amend, or rebook anything.
3. Download the official ticket PDF, then inspect page count and render **every page** to high-resolution PNG (e.g. `pdftoppm -png -r 200`).
4. Visually verify that each rendered page is a complete, legible ticket page with its QR code and journey details. Never send a cropped QR-only image: Irish Rail explicitly requires the entire ticket to be available for inspection.
5. Send the full rendered pages as native image attachments in the user-requested private channel. State which journey each page covers, but do not expose QR payload data or signed booking URLs.
6. If creating journey reminders at the same time, schedule separate reminders for each leg based on the actual departure times. Respect the user-specified lead time exactly.

## Sending mail

Only after explicit instruction. Use send scopes if needed:

```python
SCOPES = ["https://www.googleapis.com/auth/gmail.send"]
```

Construct MIME and send:

```python
import base64
from email.message import EmailMessage

message = EmailMessage()
message["To"] = "recipient@example.com"
message["From"] = "me"
message["Subject"] = "Subject here"
message.set_content("Body here")
raw = base64.urlsafe_b64encode(message.as_bytes()).decode()
gmail.users().messages().send(userId="me", body={"raw": raw}).execute()
```

Before sending, verify:

```text
From account label
Recipient(s)
Subject
Body
Attachments, if any
```

## Modify/label mail

Only after explicit instruction. Use modify scope:

```python
SCOPES = ["https://www.googleapis.com/auth/gmail.modify"]
```

Mark read/unread, archive, apply/remove labels:

```python
gmail.users().messages().modify(
    userId="me",
    id=msg_id,
    body={"addLabelIds": ["Label_123"], "removeLabelIds": ["INBOX"]},
).execute()
```

Use label IDs from `users.labels.list`; display names are not always IDs for custom labels.

## Common task patterns

### Draft Semyon's personal/professional replies

When drafting replies for Semyon, keep the voice natural, concise, and human. Avoid AI-slop markers in email drafts:

- Do not use em dashes.
- Do not use stiff semicolon joins such as `The session was useful; it helped me...`.
- Prefer plain sentence flow, contractions where natural, and specific context from the thread.
- If there is related LinkedIn/chat context, use it to avoid repeating what Semyon already said. Example: after he already thanked someone on LinkedIn for a talk, the email can start with `Thanks again for sending over the slides...` rather than reintroducing the whole meeting.
## Common task patterns

### Semyon's natural draft style

For Gmail replies and networking follow-ups, follow `references/natural-email-drafting.md`: short, warm, specific, no em dashes, no AI-slop semicolon joins, no generic polished filler, and do not imply traction/launch status that does not exist. If Semyon provides external context from LinkedIn, Discord, slides, or notes, fold that into the draft before finalizing.

### Summarize recent important mail

1. Query `newer_than:7d -is:spam -is:trash`.
2. Pull metadata/snippets first.
3. Fetch full bodies only for messages that need detail.
4. Summarize by urgency/action/account.

### Find one expected email

1. Search with sender/domain + time window.
2. Report subject/date/snippet.
3. Ask before opening/summarizing sensitive full body unless the user clearly requested it.

### Draft or update a reply

1. Use the local Gmail API/OAuth path from this skill, not Claude.ai Gmail MCP, unless Semyon explicitly asks for that fallback.
2. Verify the account label first (`personal` / `foxscopegaming`) before touching drafts.
3. Read the relevant thread and preserve its reply context: recipient(s), subject, `threadId`, and quoted/original message relationship where possible.
4. Check for adjacent context before polishing. If the relationship started or continued on LinkedIn or another channel, inspect the supplied screenshot/transcript first so the email does not repeat the conversation or misstate the stage of the product/relationship.
5. If Semyon says **do not send**, only create/update a draft and then verify it remains in Drafts and that a matching Sent search is empty.
6. Prefer updating an existing matching draft when possible. If an API/tool path can only create a replacement draft, report that plainly and warn Semyon there may be an old empty/stale draft to discard.
7. Send only if explicitly approved or if the original request unambiguously says to send.

### Semyon's natural email style

For relationship and professional follow-ups, write warm, short, and specific to the actual talk, meeting, or material shared.

- Do not use em dashes.
- Avoid semicolon joins and polished constructions such as `The session was genuinely useful; ...` that read as AI copy.
- Prefer plain sentences, contractions where natural, and one concrete takeaway over broad praise.
- Do not imply a product has launched, has users, or has data unless the thread/context confirms it. For a pre-launch product, say that directly and frame future follow-up around having something live and a small amount of real signal.
- If the sender shared slides, read them before drafting and mention one relevant takeaway rather than saying only that they were useful.
- Keep the close light. `Thanks again, and yes, let's definitely keep in touch.` is acceptable when it matches the sender's wording.
7. For tone-sensitive replies, apply `references/natural-email-drafting.md` and update the draft after each user correction rather than defending the earlier wording.

8. Send only if explicitly approved or if the original request unambiguously says to send.

8. Where appropriate, keep Semyon's preferred Irish sign-off `Le meas,` rather than forcing `Kind regards,`.
9. Send only if explicitly approved or if the original request unambiguously says to send.

## Archive a conversation

Archiving is a side effect and requires explicit user instruction. Archive the **whole thread** rather than only the newest message so the conversation leaves Inbox consistently.

1. Verify the account (`gmail-whoami <label>`).
2. **Preflight the token scope before iterating any threads.** A token that can search/read mail may still reject `threads.modify` with `insufficientPermissions`; use `https://www.googleapis.com/auth/gmail.modify` and re-authorize before attempting a partial cleanup.
3. Call `users.threads.modify` with `removeLabelIds: ["INBOX"]`.
4. Read the thread back and verify no message retains `INBOX`. Do not remove `SENT`, custom labels, or `IMPORTANT` unless the user specifically asked.

### Clean up GitHub failed-CI mail

When Semyon asks to clear GitHub failure notifications, separate **diagnosis** from mailbox modification:

1. Search `from:(github.com) ("workflow run failed" OR "checks failed" OR "build failed" OR "CI failed" OR "run failed") -is:spam -is:trash` and summarize by repo/workflow before taking action.
2. Inspect the current GitHub workflow/run state before recommending removal: historical failure mail can already be fixed, while repeated failures may be a real test regression.
3. Retain functional test/build/deploy gates. Only disable a workflow when it is clearly nonessential noise (for example, optional AI issue summaries or expensive push-time benchmarks that duplicate actual tests); state the lost capability.
4. If the user explicitly asks to clean the mail, deduplicate the matching message `threadId`s, archive only threads that still have `INBOX`, then re-query with `label:inbox` to prove none remain. Never delete these notifications by default.
5. If `gmail.modify` is absent, stop before modifying any thread. Ask Semyon to reauthorize with `google-auth-account personal --all-scopes --no-browser`, then retry and verify the archive result.

## Recurring read-only inbox triage

For a scheduled mailbox briefing, keep the collector separate from the reasoning/reporting job:

1. Use a small read-only script to query each account and persist a `last_checked` timestamp **per account** only after that account completes successfully.
2. Have the script emit metadata/snippets only: new inbox mail since the previous timestamp, existing drafts, older inbox candidates, and thread IDs that already contain a `SENT` message.
3. Treat collection and delivery as a two-phase transaction. The collector must persist its snapshot as a **pending batch** without advancing the committed cursor. The agent must use a stable batch ID, create/update any idempotent Kanban decision cards, then acknowledge the batch with the collector only after its report is ready. If the model, provider, or delivery fails first, replay the pending batch next run instead of silently losing mail.
4. Run an agent-backed cron job over that output to classify **reply needed**, **drafts ready**, **new/needs attention**, and **resolved/ignore**. It must not send, archive, label, mark read, or otherwise modify mail unless Semyon explicitly asks.
5. Treat no-reply notifications, newsletters, and expired one-time codes as non-actionable by default. Surface security alerts separately only when they could indicate an unrecognised sign-in or account change.
6. If an account fails, keep the other account's successful timestamp and report the account-specific access issue rather than silently advancing both cursors.
6. Prefer a per-account **Gmail History API `historyId`** checkpoint for incrementals: page through every history event since the last successfully committed checkpoint, dedupe message IDs, then inspect the messages’ current labels. Do not cap the event/result set. Save the API response checkpoint, not a later profile value, so changes racing the scan replay safely next time. Gmail history can expire; on its 404 expiry response, fall back to an exhaustive per-account Unix-epoch `after:<epoch>` query and seed a new history checkpoint without advancing past unseen mail. Keep a bounded recent message-ID set as an additional overlap guard.
7. If completeness matters, establish it explicitly with a one-time, read-only historical audit over **all mail except Spam/Trash** for each account, then record a successful per-account baseline. Do not call a sampled Inbox query an all-mail backfill. After that baseline, process all post-checkpoint changes (not merely `in:inbox`) so Gmail filters/archiving cannot hide new mail.
8. Keep older-mail follow-up checks separate from the incremental feed: query a bounded set of older unread inbox threads and existing drafts for context, but do not resurface them as new alerts unless a reply, review, deadline, or decision is genuinely outstanding.
8. Scheduled delivery should return exactly `[SILENT]` when there is no new actionable mail, reviewable draft, access issue, or meaningful follow-up. Do not send recurring all-clear messages.
9. For ambiguous personal, professional, financial, security, access, booking, application, or deadline-related mail, do not silently decide it is fine to ignore. Surface it once as a decision needed, with its actual received timestamp, and wait for Semyon’s direction. Only clearly non-actionable machine noise (routine newsletters/promotions/receipts/status mail, expired codes, or demonstrably recovered monitoring incidents) may be silently ignored.
10. Email-derived tasks must use the stable `email:<account>:<thread-id>` idempotency key. Reuse the existing card for later mail in the same thread/incident; do not create duplicates. When Semyon explicitly says an item is done, cancelled, dismissed, or okay to ignore, archive its linked canonical task immediately and retire future reminders. Never infer completion from silence, age, read state, or labels.
11. For a History-API collector with a pending-batch decision ledger, record exactly one durable outcome for each newly reported message before batch acknowledgement: `ignored`, `asked`, `task`, `done`, or `expired`. `asked` means an ambiguous item was surfaced to Semyon and must be rechecked/re-asked with backoff; it is not a task or a silent dismissal. Do not re-record `asked` on a re-ask; record only the final outcome. Revalidate current labels immediately before notifying, but use read/archive state only to suppress a notification, never to infer task completion.
12. When Semyon asks for response context, it is appropriate to include a short, timestamped **exact excerpt of his own latest sent reply** or an existing draft. Never quote an incoming body by default; keep the excerpt bounded and include it only when it helps him decide what to do next.

Before first use and before assuming an account is readable, inspect the token's granted scopes. A token can be valid for `gmail.send` yet lack `gmail.readonly`, in which case mailbox scanning will return `insufficientPermissions`. Re-authorize that account with the command below, then retry the read-only scan:

```bash
google-auth-account <label> --all-scopes --no-browser
```

## Troubleshooting

- `Missing token`: load `personal-google-apis` and re-authorize with `google-auth-account <label> --all-scopes --no-browser`.
- `insufficientPermissions`: do not assume the token has the requested scope just because the client asks for it. Re-authorize with `google-auth-account <label> --all-scopes --no-browser`, then retry the requested modification and verify it.
  - On a remote/headless host, the OAuth helper waits on its local callback listener (normally port 8765). If the user completes consent in a browser whose `localhost` is not the host running the helper, they can provide the resulting localhost callback URL; request that URL against the helper host's `localhost` to complete the exchange. Treat the callback's authorization code as sensitive and never repeat it in chat.
- `HttpError 403 accessNotConfigured`: Gmail API disabled in project; load `personal-google-apis` for the project link.
- Wrong account: run `gmail-whoami <label>` before side effects.
