-- How likely is a customer to order again, given they have already been silent for N days?
-- Used to choose the churn cutoff. at_risk_orders counts orders still unanswered N days later,
-- and only where the data has at least N+90 days of follow-up, so recent orders are not misread as churn.
with ord as (
    select
        order_id,
        customer_key,
        order_date,
        date_diff(lead(order_date) over w, order_date, day)     as days_to_next_order,
        date_diff(current_date(), order_date, day)              as days_observed
    from {{ ref('fct_orders') }}
    window w as (partition by customer_key order by order_date, order_id)
),
cutoffs as (
    select inactivity_days from unnest([0, 30, 60, 90, 120, 180, 270, 365, 545, 730, 1095]) as inactivity_days
)

select
    inactivity_days,
    countif(days_observed >= inactivity_days + 90
            and (days_to_next_order is null or days_to_next_order >= inactivity_days))              as at_risk_orders,
    countif(days_observed >= inactivity_days + 90
            and days_to_next_order >= inactivity_days
            and days_to_next_order < inactivity_days + 90)                                          as returned_within_90_days,
    safe_divide(
        countif(days_observed >= inactivity_days + 90 and days_to_next_order >= inactivity_days
                and days_to_next_order < inactivity_days + 90),
        countif(days_observed >= inactivity_days + 90
                and (days_to_next_order is null or days_to_next_order >= inactivity_days)))         as return_rate_90_days,
    safe_divide(
        countif(days_observed >= inactivity_days + 730 and days_to_next_order >= inactivity_days),
        countif(days_observed >= inactivity_days + 730
                and (days_to_next_order is null or days_to_next_order >= inactivity_days)))         as eventual_return_rate
from ord
cross join cutoffs
group by inactivity_days
