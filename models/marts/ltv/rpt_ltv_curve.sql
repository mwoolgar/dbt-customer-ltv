-- Grain: channel x months since first order (0 = first order only, 1..N = cumulative to the end of that month).
with customers as (
    select * from {{ ref('fct_customer_ltv') }} where is_mature_cohort
),
base as (
    select
        channel_key,
        count(*)                    as customers,
        sum(first_order_revenue)    as first_revenue,
        sum(first_order_margin)     as first_margin
    from customers
    group by 1
),
repeat_by_month as (
    select
        c.channel_key,
        date_diff(l.order_date, c.first_order_date, month)
            - if(extract(day from l.order_date) < extract(day from c.first_order_date), 1, 0) as month_index,
        sum(l.net_revenue)  as repeat_revenue,
        sum(l.net_margin)   as repeat_margin
    from customers c
    join {{ ref('fct_order_lines') }} l
        on l.customer_key = c.customer_key and l.is_valid_sale
    where l.order_id != c.first_order_id
      and l.order_date < date_add(c.first_order_date, interval {{ var('ltv_window_months') }} month)
    group by 1, 2
),
spine as (
    select b.*, m as months_since_first_order
    from base b
    cross join unnest(generate_array(0, {{ var('ltv_window_months') }})) as m
)

select
    ch.channel_name,
    s.months_since_first_order,
    safe_divide(
        s.first_revenue + sum(coalesce(r.repeat_revenue, 0)) over w, s.customers)   as cumulative_revenue_per_customer,
    safe_divide(
        s.first_margin + sum(coalesce(r.repeat_margin, 0)) over w, s.customers)     as cumulative_margin_per_customer
from spine s
join {{ ref('dim_channel') }} ch using (channel_key)
left join repeat_by_month r
    on r.channel_key = s.channel_key and r.month_index = s.months_since_first_order - 1
window w as (partition by s.channel_key order by s.months_since_first_order)
