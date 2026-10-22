-- Grain: one row per mature-cohort customer. The category of the highest-value item on the first order,
-- and whether the customer came back within the LTV window.
with c as (
    select * from {{ ref('fct_customer_ltv') }} where is_mature_cohort
),
first_lines as (
    select c.customer_key, l.product_key, l.net_revenue
    from c
    join {{ ref('fct_order_lines') }} l
        on l.order_id = c.first_order_id and l.is_valid_sale
),
ranked as (
    select
        customer_key,
        product_key,
        row_number() over (partition by customer_key order by net_revenue desc, product_key) as rn
    from first_lines
)

select
    c.customer_key,
    c.channel_key,
    c.cohort_month,
    p.category                                          as top_category,
    c.first_order_revenue,
    c.repeat_revenue,
    c.first_order_margin + c.repeat_margin              as total_margin,
    c.has_repeat_purchase
from c
left join ranked r on r.customer_key = c.customer_key and r.rn = 1
left join {{ ref('dim_product') }} p on p.product_key = r.product_key
