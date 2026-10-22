-- Grain: one row per customer with a valid purchase.
-- First order = the customer's first ORDER (by placed date, then order id). Repeat = every other order
-- inside the LTV window. Items are split by order_id, never by item date.
with first_orders as (
    select customer_key, order_id as first_order_id, order_date as first_order_date
    from {{ ref('fct_orders') }}
    where is_first_order
),
lines as (
    select * from {{ ref('fct_order_lines') }} where is_valid_sale
),
latest_month as (
    select date_trunc(max(order_date), month) as last_order_month from lines
),
customer_lines as (
    select
        f.customer_key,
        f.first_order_id,
        f.first_order_date,
        l.channel_key,
        l.order_id,
        l.net_revenue,
        l.net_margin,
        l.order_id = f.first_order_id as is_first_order
    from first_orders f
    join lines l using (customer_key)
    where l.order_date < date_add(f.first_order_date, interval {{ var('ltv_window_months') }} month)
)

select
    customer_key,
    any_value(channel_key)                                  as channel_key,
    first_order_id,
    first_order_date,
    date_trunc(first_order_date, month)                     as cohort_month,
    sum(if(is_first_order, net_revenue, 0))                 as first_order_revenue,
    sum(if(is_first_order, net_margin, 0))                  as first_order_margin,
    sum(if(not is_first_order, net_revenue, 0))             as repeat_revenue,
    sum(if(not is_first_order, net_margin, 0))              as repeat_margin,
    count(distinct order_id)                                as total_orders,
    countif(not is_first_order) > 0                         as has_repeat_purchase,
    -- Only cohorts that have had the full window to play out count towards LTV
    date_add(date_trunc(first_order_date, month), interval {{ var('ltv_window_months') }} month)
        <= any_value(latest_month.last_order_month)         as is_mature_cohort
from customer_lines
cross join latest_month
group by customer_key, first_order_id, first_order_date
