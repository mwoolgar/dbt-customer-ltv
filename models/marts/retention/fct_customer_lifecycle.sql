-- Grain: one row per customer with a valid purchase, as of today.
-- "Churn" is inactivity (no subscriptions in this data): no order for more than var churn_days.
with cust as (
    select
        customer_key,
        any_value(channel_key)      as channel_key,
        min(order_date)             as first_order_date,
        max(order_date)             as last_order_date,
        count(*)                    as orders,
        sum(net_revenue)            as net_revenue,
        sum(net_margin)             as net_margin
    from {{ ref('fct_orders') }}
    group by 1
),
aged as (
    select
        *,
        date_diff(current_date(), last_order_date, day)                                 as days_since_last_order,
        safe_divide(date_diff(last_order_date, first_order_date, day), orders - 1)      as avg_days_between_orders
    from cust
),
scored as (
    select
        *,
        ntile(5) over (order by days_since_last_order desc)     as recency_score,   -- 5 = most recent
        least(orders, 5)                                        as frequency_score,
        ntile(5) over (order by net_revenue)                    as monetary_score
    from aged
)

select
    customer_key,
    channel_key,
    first_order_date,
    last_order_date,
    orders,
    net_revenue,
    net_margin,
    safe_divide(net_revenue, orders)                            as avg_order_value,
    avg_days_between_orders,
    days_since_last_order,
    case
        when days_since_last_order <= {{ var('active_days') }}  then 'Active'
        when days_since_last_order <= {{ var('cooling_days') }} then 'Cooling'
        when days_since_last_order <= {{ var('churn_days') }}   then 'At risk'
        else 'Lapsed'
    end                                                         as lifecycle_stage,
    if(orders = 1, 'One-time', 'Repeat')                        as customer_type,
    days_since_last_order > {{ var('churn_days') }}             as is_churned,
    recency_score,
    frequency_score,
    monetary_score,
    case
        when recency_score >= 4 and frequency_score >= 3        then 'Champions'
        when recency_score = 3 and frequency_score >= 3         then 'Loyal'
        when recency_score >= 4 and frequency_score = 1         then 'Recent one-timers'
        when recency_score <= 2 and frequency_score >= 2        then 'Slipping repeaters'
        when recency_score <= 2 and frequency_score = 1         then 'Lapsed one-timers'
        else 'Developing'
    end                                                         as rfm_segment
from scored
