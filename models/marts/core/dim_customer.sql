-- Grain: one row per registered customer. Cohort fields are null for customers who never bought.
with first_orders as (
    select customer_key, min(order_date) as first_order_date
    from {{ ref('fct_order_lines') }}
    where is_valid_sale
    group by 1
)

select
    u.customer_id                                   as customer_key,
    {{ channel_key('u.traffic_source') }}           as channel_key,
    u.country,
    u.signed_up_date,
    f.first_order_date,
    date_trunc(f.first_order_date, month)           as cohort_month,
    f.first_order_date is not null                  as has_purchased
from {{ ref('stg_thelook__users') }} u
left join first_orders f on f.customer_key = u.customer_id
