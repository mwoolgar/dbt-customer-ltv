-- Grain: acquisition month x channel x months since first order.
-- retention_rate = share of the cohort that placed an order in that calendar month (month 0 is 100% by definition).
-- Only complete calendar months are included.
with cust as (
    select customer_key, channel_key, date_trunc(order_date, month) as cohort_month
    from {{ ref('fct_orders') }}
    where is_first_order
),
last_full as (
    select date_sub(date_trunc(current_date(), month), interval 1 month) as last_full_month
),
sizes as (
    select cohort_month, channel_key, count(*) as cohort_customers
    from cust
    group by 1, 2
),
activity as (
    select
        c.cohort_month,
        c.channel_key,
        date_diff(date_trunc(o.order_date, month), c.cohort_month, month)   as months_since_first_order,
        count(distinct o.customer_key)                                      as active_customers,
        count(*)                                                            as orders,
        sum(o.net_revenue)                                                  as net_revenue
    from {{ ref('fct_orders') }} o
    join cust c using (customer_key)
    group by 1, 2, 3
),
spine as (
    select s.cohort_month, s.channel_key, s.cohort_customers, m as months_since_first_order
    from sizes s
    cross join last_full
    cross join unnest(generate_array(0, date_diff(last_full.last_full_month, s.cohort_month, month))) as m
    where s.cohort_month <= last_full.last_full_month
)

select
    sp.cohort_month,
    ch.channel_name,
    sp.months_since_first_order,
    sp.cohort_customers,
    coalesce(a.active_customers, 0)                                         as active_customers,
    safe_divide(coalesce(a.active_customers, 0), sp.cohort_customers)       as retention_rate,
    coalesce(a.orders, 0)                                                   as orders,
    coalesce(a.net_revenue, 0)                                              as net_revenue
from spine sp
join {{ ref('dim_channel') }} ch using (channel_key)
left join activity a
    on a.cohort_month = sp.cohort_month
   and a.channel_key = sp.channel_key
   and a.months_since_first_order = sp.months_since_first_order
