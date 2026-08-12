# Irish Rail booking: observed flow

Use as implementation detail, not as a guarantee that the operator UI will stay unchanged.

## Journey setup

- Logged-in account route: **Make a New Booking**.
- Passenger controls separate Adults, Children, and **Students**. Set Adult `0` and Student `1` for an eligible solo student journey.
- The student fare warning requires the traveller to hold a valid TFI Young Adult Leap Card, TFI Student Leap Card, or Translink Student Discount card. Do not accept the warning unless the user has indicated eligibility.

## Seat selection

1. Select service/fare.
2. If shown, accept the student-fare eligibility warning.
3. Choose **Manual Seat Selection** to inspect coaches and seats, otherwise automatic selection is available.
4. The observed map listed coaches A–F and availability, but did **not** label which end was toward Galway or mark travel direction. Never state that A or F is definitely the Galway end from this UI alone.
5. If a preferred end coach is sold out, select the nearest available coach/end only as an authorised best effort, and record the actual coach and seat.

## Checkout

1. Skip optional extras unless requested.
2. Confirm account details and default QR-ticket fulfilment; QR delivery uses the booking email/account.
3. Review final price, payment method, and Terms checkbox.
4. Card payment may open a Revolut / Visa 3-D Secure modal. It can require an in-app approval with a short timer. The agent must ask the user to approve it and wait for an actual booking confirmation before declaring success.

## Security

- Never put card data or vault secrets into final messages or support files.
- Scope a `BW_SESSION` to direct CLI calls and lock the vault after use when requested.
