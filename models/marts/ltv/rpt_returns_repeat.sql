-- Do customers whose FIRST ORDER was returned come back less often?
-- "Returned" here is ORDER-LEVEL: the whole first order has order_status = 'Returned' (not "the
-- customer returned one item out of several" — this dataset has no partial-order status, an order
-- is either kept or fully Returned). A Returned order has no valid items, so it contributes zero
-- revenue by construction — that's why the LTV gap below looks large even when repeat_rate doesn't.
-- For item-level return rate (what share of items in a category come back), see rpt_category_returns
-- instead; that is a different grain and a different question.
-- First order here is the first order placed with any status except Cancelled. Returned orders have no
-- valid items, so they cannot be seen through fct_customer_ltv, which only starts from a valid order.
with orders as (
    select order_id, customer_id, order_date, order_status
    from {{ ref('stg_thelook__orders') }}
    where order_status in ('Complete', 'Shipped', 'Processing', 'Returned')
),
first_orders as (
    select customer_id, order_id as first_order_id, order_date as first_order_date, order_status as first_order_status
    from (
        select *, row_number() over (partition by customer_id order by order_date, order_id) as rn
        from orders
    )
    where rn = 1
),
latest as (
    select date_trunc(max(order_date), month) as last_order_month from orders
),
mature as (
    select f.*
    from first_orders f
    cross join latest
    where date_add(date_trunc(f.first_order_date, month), interval {{ var('ltv_window_months') }} month) <= latest.last_order_month
),
outcomes as (
    select
        m.customer_id,
        m.first_order_status = 'Returned'           as first_order_returned,  -- ORDER-level: whole first order, not one item (see header comment)
        logical_or(l.order_id != m.first_order_id)  as has_repeat_purchase,
        sum(l.net_revenue)                          as window_revenue,
        sum(l.net_margin)                           as window_margin
    from mature m
    left join {{ ref('fct_order_lines') }} l
        on l.customer_key = m.customer_id
       and l.is_valid_sale
       and l.order_date >= m.first_order_date
       and l.order_date < date_add(m.first_order_date, interval {{ var('ltv_window_months') }} month)
    group by 1, 2
)

select
    first_order_returned,
    count(*)                                                        as customers,
    safe_divide(countif(coalesce(has_repeat_purchase, false)), count(*)) as repeat_rate,
    safe_divide(sum(coalesce(window_revenue, 0)), count(*))         as ltv_revenue,
    safe_divide(sum(coalesce(window_margin, 0)), count(*))          as ltv_margin
from outcomes
group by 1  -- first_order_returned
