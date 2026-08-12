---
name: personal-billing-reconciliation
description: "Use when reconcile Semyon's AI-provider bills, receipts, and subscription histories with token-usage or API-equivalent cost ledgers."
version: 1.0.0
created_by: agent
related_skills:
  - personal-gmail
  - personal-google-apis

metadata:
  harness: [hermes]
---

# Personal Billing Reconciliation

Use when Semyon asks how actual payments to OpenAI, Anthropic, Google, or other AI providers compare with a usage ledger, ccusage export, token report, card history, or provider billing portal.

## Core distinction

Treat these as different measures unless source evidence proves otherwise:

- **Actual paid:** settled charges/receipts in the billing period.
- **Estimated API-equivalent value:** token use repriced at listed or logged API rates.
- **Subscription entitlement:** access/capacity included under Plus, Pro, Max, or another plan.

Never label an API-equivalent ledger simply as “spend.” Subscription billing does not give a literal per-token mapping to standard metered API prices.

## Evidence workflow

1. Establish the ledger start/end dates, its currency, its total, and the calculation basis.
2. Search both Gmail accounts and all mail except Spam/Trash. Use several independent queries, not only a provider sender domain:
   - provider/product names: `OpenAI`, `ChatGPT`, `Codex`, `Anthropic`, `Claude`, `Google AI`, `Gemini`
   - transactional terms: `receipt`, `invoice`, `amount paid`, `payment successful`, `charged`, `billing`
   - payment intermediaries: Stripe, Apple, Google Play, PayPal, Revolut, Wise, Visa, Mastercard.
3. Fetch full candidate transactional emails and record the paid total, date, plan/product, currency, and payment status. For sparse Stripe-style receipt snippets, decode both text/plain and text/html MIME parts: the authoritative fields are usually `Amount paid`/`Paid`, line items, payment date, payment method, tax, and any card-currency conversion. Record the receipt currency and actual card charge separately when both are stated.
4. Include only settled/paid charges within the ledger period. Exclude failed payment attempts and unpaid invoices. Do not assume a recurring payment happened merely because an email says a plan will renew or because a marketing email targets a paid plan.
5. Classify top-ups/credits, recurring subscriptions, and usage separately. A top-up is confirmed cash paid but is not proof it was consumed or attributable to a project/customer without a provider usage export or explicit allocation ledger.
6. Keep provider discovery distinct from payment evidence. Account verification, OAuth sign-in notices, marketing mail, product announcements, and billing-policy notices establish that a service may have been used, but not that a charge occurred; report these as `no paid evidence found`, not zero spend.
7. Treat low-balance, stale-resource, and threshold messages as operational billing alerts. Extract their stated current balance and threshold, and report them separately from historical receipts; do not infer a replacement top-up or active subscription from the alert alone.
8. Classify each figure as one of:
   - **email-confirmed paid**
   - **user-supplied billing-history evidence**
   - **unverified/inferred**
6. If Semyon provides a billing-history screenshot, transcribe every visible row exactly. Treat rows marked **Paid** as billing evidence, then revise the totals. Screenshots can close gaps that provider email receipts leave.

## Currency and calculations

When the ledger is USD and receipts are EUR:

1. Preserve the receipt-currency subtotal.
2. Convert each paid item using the payment-date EUR/USD rate from a documented historical-rate source. Do not apply one current exchange rate to the whole period.
3. Sum converted values, then calculate:

```text
cash coverage (%) = actual paid USD / API-equivalent ledger USD × 100
leverage (×)      = API-equivalent ledger USD / actual paid USD
```

Give provider-level figures where the ledger supports a provider split, then combined figures.

## Reporting format

Keep the conclusion crisp and grounded:

```text
Actual paid: €X / ~$Y
API-equivalent logged inference: $Z
Cash coverage of reference API value: N%
Effective leverage versus metered API pricing: M×
```

Add a short caveat that this is not a claim that each subscription included exactly that many priced tokens. If billing evidence remains incomplete, state the confirmed minimum and identify what source would settle the gap (provider billing history or card statement).