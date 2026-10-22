# Known pitfalls (already hit, already fixed)

Context for a reviewer or an agent asked "has this been checked" — these are mistakes made and
caught during this project, kept here so they aren't repeated.

## 1. Item-level date used to split first vs. repeat orders (fixed 22 Oct 2026)
**What went wrong:** first order was originally defined as "all valid items on the customer's first
order date", using `order_items.created_at`. About 26% of orders have items with different
timestamps (up to 5 days apart), so part of many customers' first order was wrongly counted as a
repeat purchase.

**Effect on the numbers:** repeat rate was overstated at 38.1% (correct: ~16.4%); first-order AOV
was understated at $63.90 (correct: ~$87).

**Fix:** `fct_orders` was added (one row per order, grain-correct), and every downstream LTV model
splits first vs. repeat by `order_id` via `fct_orders.is_first_order`, never by item date.

**How it was caught:** a sense check — the repeat rate looked too high relative to the category —
not a dbt test. The existing reconciliation tests passed throughout, because totals still summed
correctly; they couldn't see that the first/repeat *split* inside those totals was wrong.

**Guard now in place:** `tests/assert_orders_match_order_lines.sql` and
`tests/assert_retention_month_zero_is_full.sql`, plus the independent reconciliation script at
`/home/claude/checks/reconcile_marts_vs_raw.sql` (rebuilds key numbers from the raw source tables
with no dbt model in the path, for a day-of-build cross-check).

## 2. Returns analysis was briefly vacuous
Early version of `rpt_returns_repeat` filtered to *returned orders* and then tried to measure their
repeat rate from *valid* items only — but a fully returned order has no valid items, so the segment
was empty by construction. Redesigned to split on the first order's *status* (Returned vs. not)
while still counting repeat purchases from valid lines on *other* orders.

## 3. Future-dated rows in the source
The dataset contains orders and items stamped a few days ahead of "today" (generator artefact).
Staging models (`stg_thelook__orders`, `stg_thelook__order_items`) filter these out at the source;
if a new mart is added that reads from the raw tables directly (like `rpt_funnel` does for events),
check whether it needs the same filter.

## Takeaway for new work
Order-of-magnitude sense checks (does this repeat rate look plausible for the category?) caught what
reconciliation totals didn't. Add both for any new metric: a total that must reconcile, and a sense
check against a plausible range.
