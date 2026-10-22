# Metric scope notes: why two "repeat rate" numbers disagree

Two certified marts both describe "how many customers buy again" and give different answers. Both
are correct — they're answering different questions. An agent or a person that quotes one number
without naming its scope will produce a figure that looks inconsistent with the other.

## The two numbers
| | `fct_customer_ltv` / `rpt_channel_ltv` | `fct_customer_lifecycle` |
|---|---|---|
| Metric | 12-month repeat rate | `customer_type` = One-time vs Repeat |
| Value (22 Oct 2026 run) | 16.4% | ~31% of customers are "Repeat" |
| Population | **Mature cohorts only** — acquired at least `ltv_window_months` (12) before the latest order month | **Every customer** with at least one valid order, regardless of when acquired |
| Repeat window | A repeat order must fall within 12 months of the *first* order | No time limit — any second order, ever, counts |
| Customers covered | 42,870 | 66,119 |

## Why both exist
- `fct_customer_ltv` exists to answer "what's a customer worth in their first 12 months", a
  comparable, apples-to-apples figure across cohorts of different ages. Including an immature
  cohort (acquired 3 months ago) would understate its 12-month LTV, since it hasn't had the full
  window to repeat yet — that's what `is_mature_cohort` guards against.
- `fct_customer_lifecycle` exists to answer "what does our customer base look like *today*", so it
  deliberately includes everyone, with no time cap on what counts as a repeat purchase.

## The rule
Never quote a repeat rate without naming which of the two you mean. In practice:
- "12-month repeat rate" / "repeat rate" in an LTV or channel-performance context → `fct_customer_ltv`
  family, mature cohorts, 12-month window. This is the one in the semantic layer's `repeat_rate` metric.
- "Share of our customers who are repeat buyers" / lifecycle or RFM context → `fct_customer_lifecycle.customer_type`,
  all customers, all-time.

If a question doesn't make clear which is meant, ask, or state the assumption and give the other
figure as a footnote. Presenting one without its scope is the kind of small inconsistency that
erodes trust in a dashboard fastest, because it's easy for a reader to stumble onto both numbers and
assume one of them is wrong.

## Worked example (real exchange, Hex agent, 22 Oct 2026)
Asked "what's our overall repeat rate across all channels" against `rpt_channel_ltv`, the agent
correctly weighted by customer count (16.4%, not a naive 16.0% average of the five channel rates —
see `03_aggregation_rules.md`), then noticed this didn't match the ~31% implied by the churn
analysis, said so explicitly, and proposed the mature-cohort restriction as the likely cause without
claiming certainty. That's the right behaviour: a correct aggregation, then flagging — not silently
resolving — the cross-mart inconsistency. This file is the answer it was reaching for.
