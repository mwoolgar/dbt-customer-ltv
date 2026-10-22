-- Grain: session source. Web events exist only for customers who went on to order,
-- so cart and purchase rates are higher than a real site-wide funnel would show.
with sessions as (
    select
        session_id,
        any_value(session_source)                   as session_source,
        logical_or(event_type = 'product')          as viewed_product,
        logical_or(event_type = 'cart')             as added_to_cart,
        logical_or(event_type = 'purchase')         as purchased,
        logical_or(event_type = 'cancel')           as cancelled
    from {{ ref('stg_thelook__events') }}
    group by session_id
)

select
    session_source,
    count(*)                                                    as sessions,
    countif(viewed_product)                                     as product_sessions,
    countif(added_to_cart)                                      as cart_sessions,
    countif(added_to_cart and purchased)                        as purchase_sessions,
    countif(cancelled)                                          as cancel_sessions,
    safe_divide(countif(added_to_cart), count(*))               as cart_rate,
    safe_divide(countif(added_to_cart and purchased), countif(added_to_cart)) as cart_to_purchase_rate,
    safe_divide(countif(cancelled), count(*))                   as cancel_rate
from sessions
group by session_source
