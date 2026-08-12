---
name: personal-financial-review
description: "Use for personal savings, spending, and investment reviews."
version: 1.0.0
author: Hermes
license: MIT

metadata:
  harness: [hermes]
---

# Personal Financial Review

## When to Use

Use when Semyon asks to assemble or assess personal spending, savings, cash accounts, investment portfolios, historical returns, or opportunity cost from statements, exports, receipts, screenshots, and multiple platforms.

This is financial organisation and education, **not regulated financial, investment, tax, mortgage, or legal advice**. Do not imply a product recommendation, a guaranteed return, or precise tax treatment without the required source data and professional confirmation.

## Core accounting model

Keep these measures visibly separate. They often overlap and must not be added together:

1. **Current snapshot** — balances and market values at their stated as-of times.
2. **Cash-flow history** — deposits, withdrawals, merchant spend, transfers, fees, interest and dividends.
3. **Investment performance** — realised P/L, unrealised P/L and distributions, each only where source evidence supports it.
4. **Purchasing-power result** — inflation-adjusted comparison against dated cash flows.
5. **Opportunity cost** — a historical counterfactual, never an actual loss or a forecast.
6. **Known financial-assets subtotal** — only accounts explicitly included; never call it total net worth if pensions, debts, other banks, assets or external brokers are missing.

A transfer between accounts is not spending, income, investment return, or a new asset. Deduplicate it before calculating totals.

## Procedure

### 1. Inventory sources and their scope

For every source, record:

- platform/account;
- coverage dates;
- whether it shows current value, trades, sales only, dividends only, or cash movements;
- currency;
- whether account identifiers or other sensitive material are present.

Do not assume a consolidated statement is a complete trading ledger. A report headed **“only sales”** or **“only dividend receipt”** cannot establish complete acquisition history or total investment performance.

For screenshots, transcribe only what is visible and label it a snapshot. Do not infer a year, platform, trade direction, or tax outcome where the image does not show it. Reconcile a same-amount cash movement across platforms only after checking date, direction and source context.

### 2. Build a current-position table first

Use a table with:

| Account/sleeve | Current value | As-of | Evidence | Treatment |
| --- | ---: | --- | --- | --- |

Include cash, money-market funds, brokerage holdings, robo portfolios, commodities, crypto and external bank reserves only when a current value is available. Keep rough user-reported values marked `approximate` rather than silently presenting them as exported balances.

Provide both:

- **cash / near-cash subtotal**, excluding market-risk assets; and
- **known financial-assets snapshot**, including only sources in the table.

State missing categories directly, for example: “excludes pension, debt, other banks, and external broker balances.”

### 3. Normalise cash flows and establish ownership

- Treat negative **Merchant** entries as merchant payment activity only when the statement’s category supports it. Do **not** automatically call the total personal lifestyle spending.
- Keep transfers, top-ups, exchanges, cash-fund moves and investment contributions separate from consumption.
- Before drawing a behavioural conclusion, classify material purchases by both **beneficiary** (`self`, `parent/family pass-through`, `gift`, `shared household`, `reimbursed`) and **purpose** (`routine`, `repair/replacement`, `project/equipment`, `travel`, `education`, `upgrade`, `discretionary`). A personal payment account can be a household or technical-buyer rail rather than a pure personal-spend ledger.
- Record parental support separately from income and net worth. It may reduce living-cost risk, but it is neither a guaranteed salary nor an owned current asset. Capture whether support is fixed, ad hoc/on-request, or limited to defined costs.
- For a forward projection, give every major upcoming cost both a **payer** and a **funding source** (`user cash`, `protected savings account`, `parent-covered`, `expected income`, or `unknown`). Do not subtract a parent-covered fee, club cost, or move cost from the user’s balance; equally, do not add the parental payment to their assets. Confirm whether any account is explicitly untouchable before treating it as available runway.
- Express lifestyle-change projections in two views: **active/term-month reduction** and **calendar-year average**. Net food savings must account for higher grocery spending, and predicted savings must remain a scenario until observed in transactions.
- Record student/business/freelance cash flows separately: current cash received, expected receivables, and gross business receipts are distinct. Do not call recurring business receipts personal profit until costs, ownership and tax treatment are known.
- Use recent 30/90/180-day views for actionable habits; long histories are useful for context but are distorted by travel, fees, tuition and major hardware.
- Aggregate merchants, then inspect high-value outliers against receipts before calling them discretionary spend.
- For recurring services, identify charges by repeated dated entries, then verify actual receipts/plan status and actual use before recommending cancellation. A high-utilisation tool subscription that repeatedly reaches capacity may be productive infrastructure rather than waste.

### 4. Reconcile investment history without double counting

Create a platform ledger containing external deposits, withdrawals, purchases, sales, dividends, fees, tax withheld and transfers out.

When money leaves Trade Republic/eToro/another broker and later appears in Revolut:

- treat it as an inter-platform transfer, not new income or new savings;
- preserve the original trade history on the source platform;
- do not add the broker balance and the transferred cash at the same point in time;
- keep a reconciliation note when the matching date or direction is uncertain.

For an external platform now at zero, capture historical trades and realised outcomes but do not treat it as a current holding.

### 5. Explain savings versus investing by time horizon

Use goal horizons, not generic one-size-fits-all allocations:

- emergency and known near-term spending: accessible, low-volatility cash/near-cash;
- house/deposit money with a short or fixed deadline: do not assume it can bear full equity risk;
- genuine 7–10+ year money: may be considered separately as long-term market-risk capital.

The question is not “cash or equities?” It is “what job and deadline does each euro have?”

### 6. Tax and return communication

- Keep gross return, fees, withholding tax, realised P/L and current value separate.
- Label Irish ETF/fund tax figures as illustrations unless acquisition lots, withdrawals, distributions, applicable rules and deemed-disposal dates have been modelled correctly.
- Explain that accumulating funds reinvest distributions, but do not infer tax treatment from the word “accumulating.”
- State that historical equity counterfactuals can fall sharply and are not forecasts.

### 7. Publish safely, only with clear authorisation

Personal financial statements, receipt exports and transaction history are highly sensitive. Before public or temporary hosting, clearly state that the page exposes account identifiers, merchant/payee history, email metadata and/or downloadable raw records. Require the user’s explicit choice for either:

- a redacted dashboard; or
- a deliberately full private-data export.

If the user explicitly chooses full export, mark the page visibly as private/sensitive, set `noindex, nofollow, noarchive`, show its temporary nature, and keep raw downloads separate from the executive summary. Verify the exact published URL and every intended download after upload.

## Review output

A useful final review has these sections:

1. What is known now — cash, near-cash and market-risk assets, with timestamps.
2. Spending — merchant-only total, recent trend, large one-offs, recurring commitments and what cannot be inferred.
3. Savings accounts — return after fees/taxes, inflation context and liquidity role.
4. Investments — current allocation, historical activity evidence, missing history and concentration/simplicity observations.
5. What is working — specific evidence, not generic praise.
6. Highest-value improvements — few, concrete changes such as goal buckets, a cash floor, subscription/cloud audit, merchant review and account-fee check.
7. Boundaries — no debt/net-worth conclusion without direct evidence; no investment or tax certainty without complete records.

## Pitfalls

- Adding inflation shortfall to opportunity cost. They are overlapping comparisons.
- Calling all negative cash movements “spending.”
- Treating a transfer back from a broker as a gain or new savings.
- Mixing current snapshots from different dates without labelling them.
- Claiming an all-time return from a statement that includes sales/dividends but not every buy.
- Telling a user to invest all cash based on a historical chart; near-term house or emergency money has a different role.
- Calling a temporary public financial page private or secure merely because it is obscure.
